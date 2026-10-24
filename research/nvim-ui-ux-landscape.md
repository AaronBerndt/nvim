# Neovim UI/UX landscape for Claude Session views

Research ticket: "What do current Neovim UI/UX tools and patterns offer for Session views?"
Date: 2026-10-24. Target: nvim 0.11.7 (installed), with 0.12 extras behind `vim.fn.has('nvim-0.12')`.

## Answer

**Overall stance:** build the views on core Neovim APIs: scratch buffers, `nvim_open_win`, winbar, extmarks and folds. Use **Claude Code hooks** as the state and reply source. Don't put snacks/nui/noice abstractions in the core. Every view below is fewer than about 200 lines of plain API code. Plugin dependencies would tie you to their release schedules: snacks has had no commits since 2026-05-25, and noice none since 2025-11-03 (see [Momentum](#picker-landscape-and-momentum)).

| View | Recommendation |
|---|---|
| **State source (all views)** | Start each Session as `claude --settings <json>`, with hooks that report back to this nvim through `$NVIM`. This is the claude-deck.nvim pattern and leaves `~/.claude/settings.json` untouched. Map the events like this. `SessionStart` means new. `UserPromptSubmit`, `PreToolUse` and `PostToolUse` mean working. `PermissionRequest`, and `Notification` with `notification_type` = `permission_prompt`, `elicitation_dialog` or `agent_needs_input`, mean **waiting (blocked)**. `Stop` means idle/done. `StopFailure` means error. `TermClose` / `SessionEnd` mean exited. Known gap: an interrupt (Esc) does **not** fire `Stop`. To catch that, poll `claude agents --json` (it reports `status` = `busy`/`waiting`/`idle` plus `waitingFor`) while the Dashboard is visible. |
| **Float + tab strip** | Use one native float from `nvim_open_win` with `border`/`title`/`footer`. The title shows the Session name and state, and the footer shows key hints. Swap Session terminal buffers into that window with `nvim_win_set_buf` instead of opening a float per Session. Set the tab strip as a window-local `winbar` built from a `%!v:lua...` expression with `%@v:lua.Fn@` click regions. Cache the strip and redraw it only on state change (`redrawstatus`). This is exactly what claude-multi.nvim does on top of snacks. Do it natively, and add the filetype to lualine's `disabled_filetypes.winbar`. For full-window mode, reuse the same buffer in `current`. |
| **Dashboard** | Use a plain `buftype=nofile` buffer with its own filetype (e.g. `claude-dashboard`). Re-render the whole buffer on every state change (it is small). Draw each row with `nvim_buf_set_lines` plus extmarks for highlights and `virt_text_pos='eol_right_align'` (0.11) for age and token counts. Keep a row-to-Session map and add buffer-local keys: `<CR>` open, `r` reply, `x` kill, `n` new, `R` rename, `?` help. This is the fugitive/Lazy-UI pattern. Sort and group the way Claude Code's own agent view does: **Needs input, then Working, then Idle, then Exited**, with the `waitingFor` reason shown inline. Don't use snacks.dashboard, which is built as a startup screen (see below). |
| **Feed** | Use the **`MessageDisplay` hook**, which streams assistant text only (`message_id`, `index`, `final`, `delta`). `Stop.last_assistant_message` works as a fallback or as the "final" text. Make the Feed an append-only `nofile` buffer with `filetype=markdown`. Each reply gets a header line `### HH:MM · <session> · <state>`, with an extmark holding the Session id. Append with `nvim_buf_set_lines(buf, -1, -1, ...)`. Auto-scroll only windows whose cursor is already on the last line (tail -f behaviour). Trim the top past N lines. Reply works like this: `r` on an entry opens a small markdown input float, and `<C-s>` sends the text into that Session's terminal. Use sidekick's method for the send: `nvim_put` inside `nvim_buf_call(termbuf)` gives a bracketed paste, then send `\r` to submit. |
| **Transcript** | Get the content from the Session's `transcript_path` JSONL, which every hook payload includes. Render it into a `nofile` markdown buffer with `## You` / `## Claude` headings and tool calls as `####` subsections. Folding: `foldmethod=expr`, `foldexpr=v:lua.vim.treesitter.foldexpr()` (async in 0.11), `foldtext=""` (highlighted first line), and `foldlevel` set so tool calls start closed. agentic.nvim folds completed tool calls the same way. For live updates, watch the file with `vim.uv.new_fs_event`, keep a byte offset, and parse and append only the new lines. Render with markview.nvim (already installed) or render-markdown.nvim. Search it with `/` or Telescope `current_buffer_fuzzy_find`. Caveat: the JSONL format is internal and "may change", and it is written asynchronously, so it can lag the turn. |
| **Picker** | **Stay on Telescope.** It is maintained (v0.2.x, commits through Aug 2026, requires nvim >= 0.11.7) but moves slowly. Put it behind a ~50-line adapter with a `vim.ui.select` fallback. For live state while the picker is open, use `Picker:refresh(new_finder, {reset_prompt=false})`. Add a custom previewer that shows the tail of the Session's terminal buffer or the last Feed entry. Don't migrate to snacks.picker now, because snacks has stalled. If you ever switch, fzf-lua has the most momentum. |
| **Notifications** | Keep `vim.notify`, which noice routes on 0.11. Debounce it the way claude-deck does: notify about 2s after entering waiting/idle, and only if the Session hasn't resumed and isn't the focused window. On 0.12 you can also set `vim.bo[termbuf].busy` and emit `nvim_echo` progress messages, so working Sessions show up natively in the statusline. |

## Core Neovim APIs (0.11 stable-installed, 0.12 stable, 0.13 nightly)

Release status: **0.12.0 shipped 2026-03-29, and 0.12.6 is the current stable (2026-10-09). Nightly is 0.13.0-dev** ([releases](https://github.com/neovim/neovim/releases)). This machine runs 0.11.7.

### Floating windows

- In 0.11, `nvim_open_win` accepts `title` and `footer`, as strings or `[text, hl]` chunks, plus `title_pos`/`footer_pos` (left/center/right), `zindex`, `fixed`, and `hide` ("the floating window will be hidden"). Source: local `runtime/doc/api.txt` (0.11.7), `nvim_open_win()`. `hide=true` lets you keep the float alive and re-show it with `nvim_win_set_config`, which makes `<M-s>` toggling instant.
- 0.11 added `'winborder'`, a default border for all floats ([news-0.11](https://github.com/neovim/neovim/blob/master/runtime/doc/news-0.11.txt)). Pass `border` explicitly so the user's global setting doesn't change your look by surprise, or respect it on purpose.
- 0.12 changes ([news-0.12](https://github.com/neovim/neovim/blob/master/runtime/doc/news-0.12.txt)):
  - "floating windows can show a 'statusline'". Use `style='minimal'` to hide it.
  - `nvim_win_set_config()` can move floats to other tabpages, so the Session float can follow you across tabs.
  - The cursor shape shows when the cursor is behind an unfocused float.
- 0.13 nightly: `zindex` now also controls the dimmed-cursor behaviour, and `FloatBorder`/`FloatTitle`/`FloatFooter` blend with the window's `Normal` background ([news](https://github.com/neovim/neovim/blob/master/runtime/doc/news.txt)).

### Winbar / statusline expressions

- `winbar` is window-local and works in floats. Use `%!v:lua.require'x'.winbar()` for a computed strip and `%N@v:lua.Fn@label%X` for click targets. 0.11 "stacks" custom highlights in `statusline`/`winbar`/`tabline` (news-0.11), so per-tab state colours combine cleanly with `WinBar`/`WinBarNC`.
- 0.12: the default statusline shows `vim.ui.progress_status()`, the `:terminal` exit code, and `'busy'` (◐). The `'busy'` option is buffer-local, and `nvim_echo` can create `Progress` messages (news-0.12). These give a native "working" indicator per Session buffer.
- `b:term_title` holds the terminal title set by the child process (`:h terminal`). It is a cheap extra label, but it isn't a state signal.

### Extmarks / virtual text / virtual lines

- 0.11 `nvim_buf_set_extmark` additions (news-0.11):
  - `conceal_lines`, which hides whole lines. Use it in the Transcript to hide metadata lines.
  - `virt_text_pos='eol_right_align'`, which right-aligns columns in the Dashboard.
  - `virt_lines_overflow='scroll'`.
- 0.12 adds a decoration provider `on_range` callback, which replaces `on_line`.
- 0.13 nightly lets `virt_lines_overflow` take `"wrap"`/`"auto"`, and `virt_lines` hl can extend to end of line.
- Pattern: render text with `set_lines` and decorate with extmarks in a single namespace. Clear and redraw the whole namespace on a full re-render. Store the Session id in extmarks (or a Lua table keyed by row) for `<CR>` actions.

### Folding

- 0.11: "Treesitter folding is now calculated asynchronously" and `vim.treesitter.foldexpr()` is "10x" faster (news-0.11). Markdown highlighting via treesitter is enabled by default in 0.12, and markdown queries use `conceal_lines`.
- `foldtext=""` renders the fold line with the text's own highlighting (0.10+). The 0.12 `fillchars` flag `foldinner` lets you tune the look.
- For the Transcript, the markdown treesitter parser folds by section, so heading structure *is* the fold structure. Design the rendered markdown around that.

### Terminal buffer APIs

- 0.11:
  - `jobstart(cmd, {term=true})` replaces `termopen`.
  - `TermRequest` fires for "OSC, DCS, or APC" sequences from the child, with `ev.data.sequence` and `cursor`.
  - Terminal reflow and OSC 8 links are supported.
  - `number`/`signcolumn`/`foldcolumn` are off by default in terminals.
  - Sources: news-0.11 and local `:h TermRequest`.
- 0.12:
  - `nvim_get_chan_info()` includes `exitcode`.
  - "[Process exited]" is now virtual text rather than buffer text, which is cleaner for a Session list.
  - DEC 2026 synchronized output reduces tearing in Claude's TUI.
  - `nvim_open_term()` accepts a non-empty buffer.
- `$NVIM` is set inside `:terminal`, so hook scripts can call back with `nvim --server "$NVIM" --remote-expr ...` or `nvim -l` (claude-deck and arborist both do this).

### vim.ui.* and the message UI

- `vim.ui.select`/`vim.ui.input` are the right fallback seam. 0.13 nightly routes more builtin "picker" menus through `vim.ui.select` and adds an input scope to `vim.ui.input`. 0.13 also adds `vim.ui.img`.
- `vim._extui` became **`ui2`** in 0.12: "a redesign of the core messages and commandline UI", which avoids "Press ENTER" prompts and provides the pager as a buffer. It is "Currently experimental", enabled with `require('vim._core.ui2').enable()` (news-0.12). 0.13 moves its config into `'messagesopt'`. It doesn't exist in 0.11.7 (no `_extui`/`_core` in the local runtime). Implication: on 0.11 keep noice. On 0.12+, ui2 is the eventual noice replacement for messages, and that matters because noice is dormant.

### Efficient live-updating buffers

- Appending: `nvim_buf_set_lines(buf, -1, -1, false, lines)` with `modifiable` toggled. Batch deltas through a `vim.schedule`d flush, at most one per ~50ms, rather than one call per hook event.
- Full re-render (Dashboard): one `set_lines` plus a namespace clear and redraw is cheap at tens of rows.
- File tailing: `vim.uv.new_fs_event` plus a byte offset. sidekick's `cli/watch.lua` is a working reference for fs_event usage.
- render-markdown only renders the visible range, with a 100ms `debounce` and a `max_file_size` cutoff ([README](https://github.com/MeanderingProgrammer/render-markdown.nvim)). It is safe on a growing Feed or Transcript.

## UI toolkits

| Toolkit | Status (GitHub API, 2026-10-24) | Fit |
|---|---|---|
| snacks.nvim | 8.2k stars. Last release v2.31.0 (2026-03-20). **Last commit 2026-05-25.** | `Snacks.win` is nice: `position` float/split/current, `footer_keys`, `fixbuf`, `backdrop`, `win:toggle()`/`hide()` ([docs/win.md](https://github.com/folke/snacks.nvim/blob/main/docs/win.md)). `Snacks.dashboard` is a declarative startup screen with `terminal` sections and `Snacks.dashboard.update()` ([docs/dashboard.md](https://github.com/folke/snacks.nvim/blob/main/docs/dashboard.md)). It isn't designed as a live list with row actions. snacks.picker supports `live`, `on_change`, `matcher.sort_empty`, and custom `finder`/`format`/`preview` ([docs/picker.md](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md)). The 5-month silence is a risk. |
| mini.nvim (nvim-mini) | 9.6k stars, commits today | `mini.pick`, `mini.notify` and `mini.starter` are small and stable. Fine to borrow ideas from, but no need to adopt. |
| noice.nvim | 5.8k stars. **Last commit 2025-11-03.** | Keep for 0.11 message routing. Don't build on its API. Plan for ui2 on 0.12+. |
| nui.nvim | 2.1k stars, active (2026-08) | Component kit (Popup/Layout/Menu/Input). Adds a dependency for things that are about 20 lines natively. Skip it. |
| render-markdown.nvim | 5.2k stars, active | `file_types` is configurable, so you can add your Feed/Transcript filetypes. Renders only the visible range. codecompanion's docs recommend it for its chat filetype ([codecompanion install docs](https://github.com/olimorris/codecompanion.nvim)). |
| markview.nvim | 3.7k stars, active, **already installed** | Hybrid mode, splitview, and treesitter-based rendering ([README](https://github.com/OXY2DEV/markview.nvim)). Either renderer works. Use whichever is already configured, and use `filetype=markdown` or register your filetype. |

**Idioms per view.** Dashboard: render a scratch buffer and use buffer-local keymaps (fugitive status, lazy.nvim UI, arborist's dashboard). Feed: an append-only `nofile` markdown buffer plus extmark metadata (codecompanion and agentic chat buffers work this way, with a `codecompanion` filetype rendered by render-markdown/markview). Transcript: a read-only markdown buffer with treesitter folds, tool calls folded (agentic.nvim `folding.tool_calls`), and `gf`-style "fold codeblocks" (codecompanion `gf`).

## Picker landscape and momentum

| Picker | Signals (2026-10-24) | Verdict |
|---|---|---|
| Telescope | 19.8k stars. Tags v0.2.0 (2025-11-29) and v0.2.1 (2025-12-31), then v0.2.2. Commits are sparse but ongoing (latest 2026-08-17). README: "Neovim >=v0.11.7", and "Only the latest version (stable) and the latest commit of HEAD (nightly) are tested". No maintenance-mode notice. | **Sound for a personal plugin you already use.** It is stable, the API is well known, and it has `Picker:refresh(finder, opts)` (`lua/telescope/pickers.lua`) for live updates. |
| snacks.picker | Feature-rich and the most "modern". sidekick defaults to it. Repo has been silent since May 2026. | Don't migrate now. |
| fzf-lua | 4.5k stars, commits today | Most actively developed. arborist and claude-deck use it. This is the switch target if Telescope ever rots. |

To keep the switch cheap, the picker module takes `items` (Session records) and returns a chosen Session through a callback. Telescope stays an implementation detail, with `vim.ui.select` as the fallback, the same way sidekick's `cli.picker` lets you choose `snacks|telescope|fzf-lua`.

## Prior art: AI/agent terminals in nvim

| Plugin | Multi-session | Status / notifications | Transcript | Borrow / avoid |
|---|---|---|---|---|
| **sidekick.nvim** (installed; 2.8k stars; last commit 2026-09-08) | Several CLI tools/sessions. `:Sidekick cli select` starts or attaches. Optional tmux/zellij persistence (`cli.mux`). | `require("sidekick.status").cli()` returns the session list, used for a lualine count. **No per-session busy/waiting detection.** Notifications cover Copilot only. | None | **Borrow:** the send queue that uses `nvim_put` inside the terminal buffer to "better simulate user input" (`cli/terminal.lua`), fs_event file watching with auto `checktime`, and `win.layout` float/side options. **Annoying:** no state awareness, so it can't tell you which session needs you. |
| **claudecode.nvim** (coder; 3.1k stars; very active) | Assumes "the open Claude terminal". Multi-instance routing isn't documented. | `:ClaudeCodeStatus` and User autocmds (`ClaudeCodeSendComplete`, `ClaudeCodeDiffOpened/Closed`). | None | WebSocket MCP server that implements Claude's IDE protocol: lock file at `~/.claude/ide/[port].lock`, plus native diff accept/reject ([README](https://github.com/coder/claudecode.nvim)). **Borrow (optional, later):** IDE-integration diffs. **Avoid:** coupling multi-session to it, since one server is shared by every session. |
| **claude-deck.nvim** (tbsmcd, formerly claude-terminals) | Yes, splits. `:q` only hides, and the session keeps running. | **The best reference.** Hooks are injected via `claude --settings <json>` and forwarded over `$NVIM`. States: New, Running, Waiting, **Needs you**, Exited, coloured with the Okabe-Ito palette. Notification is delayed 2s and suppressed when that terminal is focused. | `ct read`, and `ct list --json` exposes `transcript_path` | **Borrow:** the state machine, injecting settings so the user's config is untouched, and debounced, focus-aware notifications. **Known gaps it documents:** an interrupt doesn't fire `Stop`; terminals are lost when nvim exits (resume with `claude --resume`); the transcript format "may change". ([repo](https://github.com/tbsmcd/claude-deck.nvim)) |
| **arborist.nvim** (young) | Sessions per git worktree | Hooks via `nvim -l`: Stop, PostToolUse, **PermissionRequest**, Notification, SessionStart, SessionEnd. Split dashboard with Running/Idle/Needs input/Detached. lualine turns yellow when any session needs permission. Notification queue. | None | **Borrow:** the dashboard keymap set (`<CR>`, `x`, `X`, `r`, `q`, `?`), persisting sessions to `stdpath("data")` so they can be resumed, and the lualine colour-by-worst-state idea. ([repo](https://github.com/tomascaslo/arborist.nvim)) |
| **claude-multi.nvim** (young) | Yes. **Winbar tab strip** in a centered float or right split, built on snacks. | Only `[N]`/`[R]` markers. No state. | None | Shows that the winbar-tab-in-float UX works. Add state icons, which it lacks. ([repo](https://github.com/mb6611/claude-multi.nvim)) |
| **multiclaudecode.nvim** | Yes | Hooks for completion notifications, plus a statusline function | None | Confirms hooks are the standard state mechanism. ([repo](https://github.com/qtnx/multiclaudecode.nvim)) |
| **codecompanion.nvim** (6.9k stars, very active) | Multiple chat buffers. Can use Claude Code through ACP. | `_G.codecompanion_chat_metadata` (adapter, tokens, cycles) for statuslines | The chat buffer *is* the transcript: markdown, render-markdown/markview, `gf` folds codeblocks | **Borrow:** a global metadata table keyed by bufnr for statusline use, and a dedicated filetype rendered by a markdown renderer. It isn't a terminal manager. |
| **agentic.nvim** (installed) | "Independent Chat sessions for each Neovim Tab" over ACP | Permission prompts with 1/2/3 one-key answers | Sidebar markdown chat. Completed tool calls auto-fold with a `threshold`, and the header and status stay visible. | **Borrow:** tool-call folding rules for the Transcript and one-key permission answers. ACP is an alternative architecture (structured events instead of a TUI); out of scope here. |
| **avante.nvim** (avante-corp; 18.2k stars) | Sidebar chat | n/a | Sidebar | Cursor-style single sidebar. Little to borrow for multi-session. |
| **toggleterm.nvim** (5.6k stars; last commit 2025-03) | Numbered terminals | None | n/a | Effectively unmaintained. Native `jobstart{term=true}` plus your own float covers it. |
| **Claude Code agent view** (`claude agents`, first-party, research preview) | All background sessions | Groups: Pinned, Ready for review, **Needs input**, Working, Completed. `Space` peeks and replies without attaching. `--json` gives `state` (`working`/`blocked`/`done`/`failed`/`stopped`), `status` (`busy`/`waiting`/`idle`) and `waitingFor`. | `claude logs <id>` | **Borrow:** the vocabulary and waiting-first ordering, plus "peek and reply without attaching" (= Feed reply). `claude agents --json` is "the supported interface for reading session state from outside Claude Code" ([docs](https://code.claude.com/docs/en/agent-view)). Use it to reconcile with the hooks. |

### Hook facts that drive the design ([hooks docs](https://code.claude.com/docs/en/hooks))

- Every payload includes `session_id`, `transcript_path` (a `.jsonl` file; "written asynchronously and may lag the current turn"), `cwd` and `hook_event_name`.
- `Notification` carries `message`, `title` and `notification_type`. Types include `permission_prompt`, `idle_prompt`, `elicitation_dialog`, `agent_needs_input` and `agent_completed`.
- `MessageDisplay` "receives assistant message text only" in streamed batches: `turn_id`, `message_id`, `index`, `final`, `delta`. It is the ideal Feed source.
- `Stop` / `SubagentStop` carry `last_assistant_message`. The docs recommend it over parsing the transcript.
- `PermissionRequest` carries `tool_name` and `tool_input`. Show "Bash: rm -rf node_modules" right in the Dashboard row and in the notification.

## Sources

- Neovim releases: https://github.com/neovim/neovim/releases
- news-0.11 / news-0.12 / news (0.13-dev): https://github.com/neovim/neovim/tree/master/runtime/doc (`news-0.11.txt`, `news-0.12.txt`, `news.txt`)
- Local 0.11.7 runtime docs: `api.txt` (`nvim_open_win`), `terminal.txt`, `autocmd.txt` (`TermRequest`)
- Claude Code hooks: https://code.claude.com/docs/en/hooks
- Claude Code agent view: https://code.claude.com/docs/en/agent-view
- snacks.nvim docs: https://github.com/folke/snacks.nvim/tree/main/docs (`win.md`, `picker.md`, `dashboard.md`)
- render-markdown.nvim: https://github.com/MeanderingProgrammer/render-markdown.nvim
- markview.nvim: https://github.com/OXY2DEV/markview.nvim
- telescope.nvim: https://github.com/nvim-telescope/telescope.nvim (README; `lua/telescope/pickers.lua` `Picker:refresh`)
- fzf-lua: https://github.com/ibhagwan/fzf-lua
- sidekick.nvim: https://github.com/folke/sidekick.nvim (README; `lua/sidekick/cli/terminal.lua`, `cli/watch.lua`, `status.lua`)
- claudecode.nvim: https://github.com/coder/claudecode.nvim
- claude-deck.nvim: https://github.com/tbsmcd/claude-deck.nvim
- arborist.nvim: https://github.com/tomascaslo/arborist.nvim
- claude-multi.nvim: https://github.com/mb6611/claude-multi.nvim
- multiclaudecode.nvim: https://github.com/qtnx/multiclaudecode.nvim
- codecompanion.nvim: https://github.com/olimorris/codecompanion.nvim (`doc/usage/ui.md`, `doc/usage/chat-buffer/index.md`, `doc/installation.md`)
- agentic.nvim: https://github.com/carlos-algms/agentic.nvim (README "Folding", "Features")
- Repo activity and star counts: GitHub REST API `repos/{owner}/{repo}`, `/commits`, `/releases`, queried 2026-10-24
