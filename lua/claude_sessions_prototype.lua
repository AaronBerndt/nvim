-- PROTOTYPE — throwaway. Answers the ticket "Prototype Session window layout and switching".
-- Three variants of how Sessions are shown and switched, flipped with a bottom switcher bar.
-- Sessions are FAKE: plain shells with a simulated Session State that changes every few seconds.
--
-- Run:   :luafile ~/.config/nvim/lua/claude_sessions_prototype.lua
-- Keys (all variants, normal mode; <C-q> also works from terminal mode):
--   <leader>ss  toggle Sessions         <leader>sn  new fake Session
--   <M-s>       toggle from ANY mode    <C-q> / q   hide (terminal / normal mode)
--   <leader>sp  Telescope picker        floats auto-hide when you click or <C-w> away
--   ]s / [s     next / prev Session     (also <C-n>/<C-p> in terminal mode)
--   <leader>sv  flip float <-> split    <leader>]v / <leader>[v  next / prev VARIANT
--   <leader>s?  print full prototype state

local P = { sessions = {}, current = nil, win = nil, variant = 1, mode_override = nil }
local STATES = { "working", "waiting", "idle" }
local ICON = { working = "⚙", waiting = "⏸", idle = "✓", exited = "✗" }
local PROJECTS = { "nvim", "zipnosis", "api", "web", "docs" }

local VARIANTS = {
  { key = "A", name = "Float stack: one big float, cycle in place" },
  { key = "B", name = "Side pane + tab strip winbar" },
  { key = "C", name = "Picker-first, bottom split" },
}

-- ── sessions ────────────────────────────────────────────────────────────
local function new_session()
  local n = #P.sessions + 1
  local project = PROJECTS[((n - 1) % #PROJECTS) + 1]
  local buf = vim.api.nvim_create_buf(false, true)
  local s = { id = n, name = project .. ":" .. n, project = project, buf = buf, state = "working", since = os.time() }
  vim.api.nvim_buf_call(buf, function()
    vim.fn.termopen({ "bash", "-c", "echo 'PROTOTYPE fake Session " .. s.name .. " — pretend this is claude'; exec bash" })
  end)
  vim.keymap.set({ "t", "n" }, "<C-q>", function() P.hide() end, { buffer = buf })
  vim.keymap.set("n", "q", function() P.hide() end, { buffer = buf })
  vim.keymap.set("t", "<C-n>", function() P.cycle(1) end, { buffer = buf })
  vim.keymap.set("t", "<C-p>", function() P.cycle(-1) end, { buffer = buf })
  table.insert(P.sessions, s)
  return s
end

local function label(s)
  return string.format("%s %s  (%s, %ds)", ICON[s.state], s.name, s.state, os.time() - s.since)
end

local function idx(s)
  for i, x in ipairs(P.sessions) do if x == s then return i end end
end

-- ── window helpers ──────────────────────────────────────────────────────
local function win_valid() return P.win and vim.api.nvim_win_is_valid(P.win) end

function P.hide()
  if win_valid() then vim.api.nvim_win_close(P.win, true) end
  P.win = nil
end

local function open_float(s, w, h)
  local W, H = vim.o.columns, vim.o.lines
  local width, height = math.floor(W * w), math.floor(H * h)
  P.win = vim.api.nvim_open_win(s.buf, true, {
    relative = "editor", width = width, height = height,
    row = math.floor((H - height) / 2) - 1, col = math.floor((W - width) / 2),
    border = "rounded", title = " " .. label(s) .. string.format("  [%d/%d] ", idx(s), #P.sessions),
    title_pos = "center",
  })
end

local function open_split(s, cmd)
  vim.cmd(cmd)
  P.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(P.win, s.buf)
end

local function tabstrip()
  local parts = {}
  for i, s in ipairs(P.sessions) do
    local t = string.format(" %d %s %s ", i, s.name, ICON[s.state])
    table.insert(parts, (s == P.current and "%#TabLineSel#" or "%#TabLine#") .. t)
  end
  return table.concat(parts, "%#TabLineFill# ")
end

-- ── variants: each owns show(s) ─────────────────────────────────────────
local show = {}

-- A: one large centered float; cycling swaps the buffer inside the same float.
show[1] = function(s, mode)
  if mode == "split" then open_split(s, "botright vsplit") return end
  open_float(s, 0.85, 0.85)
end

-- B: right-side pane (40%) with every Session as a tab in the winbar.
show[2] = function(s, mode)
  if mode == "float" then open_float(s, 0.6, 0.7) else
    open_split(s, "botright " .. math.floor(vim.o.columns * 0.4) .. "vsplit")
  end
  vim.wo[P.win].winbar = "%{%v:lua.ClaudeProtoTabstrip()%}"
end

-- C: bottom split (35%); the toggle key goes through the picker when >1 Session.
show[3] = function(s, mode)
  if mode == "float" then open_float(s, 0.7, 0.6) return end
  open_split(s, "botright " .. math.floor(vim.o.lines * 0.35) .. "split")
end

_G.ClaudeProtoTabstrip = tabstrip

local function default_mode() return P.variant == 1 and "float" or "split" end

function P.show(s)
  P.hide()
  P.current = s
  show[P.variant](s, P.mode_override or default_mode())
  vim.cmd("startinsert")
end

function P.cycle(d)
  if #P.sessions == 0 then return end
  local i = ((idx(P.current) or 1) - 1 + d) % #P.sessions + 1
  P.show(P.sessions[i])
end

function P.picker()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then return vim.notify("telescope missing") end
  local finders, conf = require("telescope.finders"), require("telescope.config").values
  local actions, state = require("telescope.actions"), require("telescope.actions.state")
  local previewers = require("telescope.previewers")
  -- waiting first, then working, then idle
  local order = { waiting = 1, working = 2, idle = 3, exited = 4 }
  local list = vim.deepcopy(P.sessions, true)
  table.sort(list, function(a, b) return order[a.state] < order[b.state] end)
  pickers.new({}, {
    prompt_title = "Claude Sessions (PROTOTYPE)",
    finder = finders.new_table({
      results = list,
      entry_maker = function(s)
        return { value = s, ordinal = s.name .. " " .. s.state,
          display = string.format("%s  %-12s %-10s %-8s %ds", ICON[s.state], s.name, s.project, s.state, os.time() - s.since) }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry)
        local lines = vim.api.nvim_buf_get_lines(entry.value.buf, 0, -1, false)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    }),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local e = state.get_selected_entry(); actions.close(bufnr)
        for _, s in ipairs(P.sessions) do if s.id == e.value.id then P.show(s) end end
      end)
      return true
    end,
  }):find()
end

function P.toggle()
  if win_valid() then return P.hide() end
  if #P.sessions == 0 then return P.show(new_session()) end
  if P.variant == 3 and #P.sessions > 1 then return P.picker() end
  P.show(P.current or P.sessions[1])
end

-- ── switcher bar (the "floating bottom bar" of the prototype) ───────────
local bar = { buf = vim.api.nvim_create_buf(false, true), win = nil }
local function draw_bar()
  local v = VARIANTS[P.variant]
  local text = string.format(" ◀ <leader>[v   %s (%s)   <leader>]v ▶ ", v.key, v.name)
  vim.api.nvim_buf_set_lines(bar.buf, 0, -1, false, { text })
  local w = vim.fn.strdisplaywidth(text)
  local cfg = { relative = "editor", width = w, height = 1, row = vim.o.lines - 4,
    col = math.floor((vim.o.columns - w) / 2), style = "minimal", border = "single", focusable = false, zindex = 250 }
  if bar.win and vim.api.nvim_win_is_valid(bar.win) then vim.api.nvim_win_set_config(bar.win, cfg)
  else bar.win = vim.api.nvim_open_win(bar.buf, false, cfg) end
end

function P.dump()
  local lines = { "variant " .. VARIANTS[P.variant].key .. ", mode " .. (P.mode_override or default_mode()) ..
    ", current " .. (P.current and P.current.name or "-") }
  for _, s in ipairs(P.sessions) do table.insert(lines, "  " .. label(s)) end
  print(table.concat(lines, "\n"))
end

function P.set_variant(d)
  local was_open = win_valid()
  P.hide(); P.mode_override = nil
  P.variant = (P.variant - 1 + d) % #VARIANTS + 1
  draw_bar(); P.dump()
  if was_open and P.current then P.show(P.current) end
end

-- ── fake Session State churn ────────────────────────────────────────────
local timer = vim.uv.new_timer()
timer:start(4000, 4000, vim.schedule_wrap(function()
  if #P.sessions == 0 then return end
  local s = P.sessions[math.random(#P.sessions)]
  local new = STATES[math.random(#STATES)]
  if new ~= s.state then
    s.state, s.since = new, os.time()
    if new ~= "working" and s ~= P.current then
      vim.notify(string.format("%s %s is %s", ICON[new], s.name, new), vim.log.levels.INFO, { title = "Claude (PROTOTYPE)" })
    end
    if win_valid() and vim.api.nvim_win_get_config(P.win).relative ~= "" then
      vim.api.nvim_win_set_config(P.win, { title = " " .. label(P.current) .. string.format("  [%d/%d] ", idx(P.current), #P.sessions), title_pos = "center" })
    end
    vim.cmd("redrawstatus!")
  end
end))

-- ── keys ────────────────────────────────────────────────────────────────
local map = function(l, f, d) vim.keymap.set("n", l, f, { desc = "PROTO " .. d }) end
map("<leader>ss", P.toggle, "toggle Sessions")
map("<leader>sn", function() P.show(new_session()) end, "new Session")
map("<leader>sp", P.picker, "pick Session")
map("]s", function() P.cycle(1) end, "next Session")
map("[s", function() P.cycle(-1) end, "prev Session")
map("<leader>sv", function()
  P.mode_override = (P.mode_override or default_mode()) == "float" and "split" or "float"
  if P.current then P.show(P.current) end
end, "flip float/split")
map("<leader>]v", function() P.set_variant(1) end, "next variant")
map("<leader>[v", function() P.set_variant(-1) end, "prev variant")
map("<leader>s?", P.dump, "dump state")
vim.api.nvim_create_user_command("ProtoVariant", function(o)
  local target = ({ A = 1, B = 2, C = 3 })[o.args:upper()]
  if target then P.set_variant(target - P.variant) else P.set_variant(1) end
end, { nargs = "?", complete = function() return { "A", "B", "C" } end })

-- one toggle key that works from ANY mode, including inside the terminal
vim.keymap.set({ "n", "t" }, "<M-s>", P.toggle, { desc = "PROTO toggle Sessions (any mode)" })

-- floats auto-hide when focus leaves them (mouse click, <C-w>w, picker, ...)
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    local w = vim.api.nvim_get_current_win()
    if w == P.win and vim.api.nvim_win_get_config(w).relative ~= "" then
      vim.schedule(function() if P.win == w then P.hide() end end)
    end
  end,
})

-- seed three fake Sessions so switching is meaningful immediately
for _ = 1, 3 do new_session() end
draw_bar()
vim.notify("Claude Sessions PROTOTYPE loaded — <leader>ss to toggle, <leader>]v to change variant", vim.log.levels.INFO)
