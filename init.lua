local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "
vim.g.maplocalleader = ","
require("lazy").setup({
	"folke/which-key.nvim",
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			picker = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
	},
	"kchmck/vim-coffee-script",
	"folke/neodev.nvim",
	"shaunsingh/nord.nvim",
	"justinmk/vim-sneak",
	"github/copilot.vim",
	"metakirby5/codi.vim",
{
  "folke/sidekick.nvim",
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = "tmux",
        enabled = true,
      },
    },

  },
  keys = {
    {
      "<leader>ac",
      function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
      desc = "Sidekick Toggle Claude",
    },
  },
},
	"svermeulen/vim-subversive",
	{
		"OXY2DEV/markview.nvim",
		lazy = false,
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{ "mistweaverco/kulala.nvim", opts = {} },
	{
		"folke/neoconf.nvim",
		cmd = "Neoconf",
	},
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"hrsh7th/nvim-cmp", -- Optional: For using slash commands and variables in the chat buffer
			"nvim-telescope/telescope.nvim", -- Optional: For using slash commands
			{ "stevearc/dressing.nvim", opts = {} }, -- Optional: Improves `vim.ui.select`
		},
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = {
						adapter = "copilot",
					},
					agent = {
						adapter = "copilot",
					},
				},
			})
			vim.keymap.set("n", "<leader>cc", ":CodeCompanionChat<CR>", {})
		end,
	},

	{
		"tpope/vim-fugitive",
		config = function()
			vim.keymap.set("n", "<leader>gs", ":Git<CR>", {})
			vim.keymap.set("n", "<leader>gc", ":Git commit<CR>", {})
			vim.keymap.set("n", "<leader>gp", ":Git push<CR>", {})
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*", --
		build = "make install_jsregexp",
	},
	{
		"stevearc/conform.nvim",
		opts = {},

		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "isort", "black" },
					typescript = { "prettierd" },
					json = { "prettierd" },
					typescriptreact = { "prettierd" },
					javascript = { "prettierd" },
				},
			})

			vim.keymap.set("n", "<leader>p", require("conform").format, {})
		end,
	},
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = true,
	},
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		"numToStr/Comment.nvim",
		lazy = false,
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				ensure_installed = {
					"ruby",
					"lua",
					"vim",
					"vimdoc",
					"javascript",
					"html",
					"css",
					"typescript",
					"tsx",
					"xml",
				},
				sync_install = false,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local colors = {
				blue = "#80a0ff",
				cyan = "#79dac8",
				black = "#080808",
				white = "#c6c6c6",
				red = "#ff5189",
				violet = "#d183e8",
				grey = "#303030",
			}

			local bubbles_theme = {
				normal = {
					a = { fg = colors.black, bg = colors.violet },
					b = { fg = colors.white, bg = colors.grey },
					c = { fg = colors.black, bg = colors.black },
				},
				insert = { a = { fg = colors.black, bg = colors.blue } },
				visual = { a = { fg = colors.black, bg = colors.cyan } },
				replace = { a = { fg = colors.black, bg = colors.red } },

				inactive = {
					a = { fg = colors.white, bg = colors.black },
					b = { fg = colors.white, bg = colors.black },
					c = { fg = colors.black, bg = colors.black },
				},
			}
			require("lualine").setup({
				options = {
					theme = bubbles_theme,
					component_separatorsder = "|",
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = {
						{ "mode", separator = { left = "" }, right_padding = 2 },
					},
					lualine_b = { "filename", "branch" },
					lualine_c = { "fileformat" },
					lualine_x = {},
					lualine_y = { "filetype", "progress" },
					lualine_z = {
						{ "location", separator = { right = "" }, left_padding = 2 },
					},
				},
				inactive_sections = {
					lualine_a = { "filename" },
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = { "location" },
				},
				tabline = {},
				extensions = {},
			})
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },

		config = function()
			local builtin = require("telescope.builtin")
			local conf = require("telescope.config").values
			local harpoon = require("harpoon")
			harpoon:setup({})
			local function toggle_telescope(harpoon_files)
				local file_paths = {}
				for _, item in ipairs(harpoon_files.items) do
					table.insert(file_paths, item.value)
				end

				require("telescope.pickers")
					.new({}, {
						prompt_title = "Harpoon",
						finder = require("telescope.finders").new_table({
							results = file_paths,
						}),
						previewer = conf.file_previewer({}),
						sorter = conf.generic_sorter({}),
					})
					:find()
			end

			vim.keymap.set("n", "<leader>fh", function()
				toggle_telescope(harpoon:list())
			end, { desc = "Open harpoon window" })
			vim.keymap.set("n", "<leader>aa", function()
				harpoon:list():add()
			end)

			vim.keymap.set("n", "<leader>a1", function()
				harpoon:list():select(1)
			end)
			vim.keymap.set("n", "<leader>a2", function()
				harpoon:list():select(2)
			end)
			vim.keymap.set("n", "<leader>a3", function()
				harpoon:list():select(3)
			end)
			vim.keymap.set("n", "<leader>a4", function()
				harpoon:list():select(4)
			end)

			-- Toggle previous & next buffers stored within Harpoon list
			vim.keymap.set("n", "<C-S-P>", function()
				harpoon:list():prev()
			end)
			vim.keymap.set("n", "<C-S-N>", function()
				harpoon:list():next()
			end)

			vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
			vim.keymap.set("n", "<leader>gb", builtin.git_branches, {})
		end,
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/neotest-plenary",
			"nvim-neotest/neotest-jest",
			"thenbe/neotest-playwright",
			"nvim-neotest/nvim-nio",
		},
		opts = { adapters = { "neotest-plenary", "neotest-jest", "neotest-playwright" } },
		status = { virtual_text = true },
		output = { open_on_run = true },
		estConfigFile = function(file)
			if string.find(file, "/packages/") then
				return string.match(file, "(.-/[^/]+/)src") .. "jest.config.ts"
			end

			return vim.fn.getcwd() .. "/jest.config.ts"
		end,
		config = function()
			require("neotest").setup({

				adapters = {
					require("neotest-jest")({
						jest_command = "jest --watch",
					}),
				},
			})

			vim.keymap.set("n", "<leader>tf", ":Neotest run file<CR>", {})
			vim.keymap.set("n", "<leader>tn", ":Neotest run run<CR>", {})
			vim.keymap.set("n", "<leader>ta", ":Neotest attach<CR>", {})
			vim.keymap.set("n", "<leader>ts", ":Neotest summary<CR>", {})
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			routes = {
				{
					filter = {
						event = "notify",
						find = "No information available",
					},
					opts = {
						skip = true,
					},
				},
			},
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		config = function()
			local noice = require("noice")

			noice.setup({
				lsp = {
					-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
					},
				},
				-- you can enable a preset for easier configuration
				presets = {
					bottom_search = true, -- use a classic bottom cmdline for search
					command_palette = true, -- position the cmdline and popupmenu together
					long_message_to_split = true, -- long messages will be sent to a split
					inc_rename = false, -- enables an input dialog for inc-rename.nvim
					lsp_doc_border = false, -- add a border to hover docs and signature help
				},
			})

			function OpenFileInVsplitNoice()
				-- Define the file paths
				local files = {
					"~/.config/nvim/init.lua",
					"~/.nvimrc",
				}

				-- Format the options for Noice's selection menu
				local options = {}
				for i, file in ipairs(files) do
					table.insert(options, {
						text = i .. ": " .. file,
						action = function()
							vim.cmd("vsplit " .. file)
						end,
					})
				end

				-- Show the Noice selection menu
				noice.menu({
					title = "Select a File",
					items = options,
					on_cancel = function()
						print("File selection canceled.")
					end,
				})
			end

			-- Map the function to a keybinding
			vim.api.nvim_set_keymap(
				"n",
				"<leader>m",
				":lua OpenFileInVsplitNoice()<CR>",
				{ noremap = true, silent = true }
			)
		end,
	},
	"VonHeikemen/lsp-zero.nvim",
	{
		"williamboman/mason.nvim",
		dependencies = { "williamboman/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },

		config = function()
			local lsp_zero = require("lsp-zero")
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "ts_ls", "lua_ls", "eslint", "html", "solargraph", "angularls" },
			})

			on_attach = function(_, _)
				-- local buf = { buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
				vim.keymap.set("n", "<leader>ar", vim.lsp.buf.rename, {})
				vim.keymap.set("n", "<leader>aw", vim.lsp.buf.code_action, {})
				vim.keymap.set("n", "<leader>ak", vim.lsp.buf.hover, {})
				vim.api.nvim_exec([[ autocmd CursorHold * lua vim.lsp.buf.hover()]], false)
			end

			require("lspconfig").ts_ls.setup({
				on_attach = on_attach,
			})

			require("lspconfig").html.setup({
				on_attach = on_attach,
			})

			require("lspconfig").eslint.setup({
				on_attach = on_attach,
			})

			require("lspconfig").lua_ls.setup({
				on_attach = on_attach,
			})

			require("lspconfig").angularls.setup({
				on_attach = on_attach,
			})

			require("lspconfig").coffeesense.setup({
				on_attach = on_attach,
			})

			require("lspconfig").solargraph.setup({
				on_attach = on_attach,
			})
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup({
				filesystem = {
					filtered_items = {
						visible = true,
						show_hidden_count = true,
						hide_dotfiles = false,
						hide_gitignored = false,
					},
					follow_current_file = {
						enabled = true,
						leave_dirs_open = false,
					},
				},
				buffers = { follow_current_file = { enable = true } },
			})

			vim.keymap.set("n", "<leader>n", ":Neotree toggle<CR>")
		end,
	},
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		lazy = true,
		ft = "markdown",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = {
			workspaces = {
				{
					name = "personal",
					path = "~/gitstuff/obsidian",
				},
			},
		},
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && yarn install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},

	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"saadparwaiz1/cmp_luasnip",
		},

		config = function()
			local cmp = require("cmp")

			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = {
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.close(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				},
				sources = {
					{ name = "nvim_lsp" },
					{ name = "nvim_lua" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "cmdline" },
					{ name = "luasnip" },
				},
			})
		end,
	},
})

-- settings
vim.g.mapleader = " "
vim.opt.spell = true
vim.opt.spelllang = { "en_us" }
vim.cmd([[colorscheme tokyonight-storm]])
vim.opt.number = true
vim.opt.clipboard = "unnamed"
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.api.nvim_set_hl(0, "LineNr", { fg = "white" })
vim.opt.conceallevel = 2

-- Functions
function ZipnosisCommand()
	require("telescope.builtin").find_files({ cwd = "~/gitstuff/zipnosis", prompt_title = "zipnosis" })
end

function ZipnosisGrepCommand()
	require("telescope.builtin").live_grep({ cwd = "~/gitstuff/zipnosis/", prompt_title = "zipnosis grep" })
end

function FlorenceGrepCommand()
	require("telescope.builtin").live_grep({
		cwd = "~/gitstuff/florence-fe",
		prompt_title = "florence grep",
	})
end

function FlorenceCommand()
	require("telescope.builtin").find_files({
		cwd = "~/gitstuff/florence-fe",
		prompt_title = "florence",
	})
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local commands = {
	{ name = "Start Dev Server", command = "cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx dev", terminal = 1 },
	{ name = "Start Storybook", command = "cd ~/gitstuff/florence-fe && nx storybook virtual-care", terminal = 2 },
	{ name = "Start Nginx", command = "cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx nginx", terminal = 3 },
	{
		name = "Start Nginx (Alternate)",
		command = "cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx nginx",
		terminal = 4,
	},
	{ name = "Run Tests", command = "cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx test", terminal = 5 },
	{
		name = "Run Storybook Tests",
		command = "cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx test-storybook",
		terminal = 6,
	},
	{ name = "Run Linter", command = "cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx lint", terminal = 7 },
	{ name = "Yarn dev", command = "yarn dev", terminal = 8 },
	{ name = "Yarn Storybook", command = "yarn storybook", terminal = 9 },
}

-- Function to run the command in ToggleTerm
local function run_command(entry)
	if not entry then
		return
	end

	local term_cmd = string.format(
		entry.terminal .. "TermExec cmd='%s' direction=float go_back=0 id=%d",
		entry.command,
		entry.terminal
	)

	vim.cmd(term_cmd)
end

-- Telescope Picker for Commands
local function open_command_picker()
	pickers
		.new({}, {
			prompt_title = "Run Command",
			finder = finders.new_table({
				results = commands,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name,
						ordinal = entry.name,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					run_command(selection.value)
				end)
				return true
			end,
		})
		:find()
end

-- Function to open a running terminal in ToggleTerm

local function get_open_terminals()
	local terminals = {}
	for i = 1, 10 do -- Check up to 10 terminals
		local ok, _ = pcall(vim.cmd, string.format("ToggleTermToggleAll id=%d", i))
		if ok then
			table.insert(terminals, { name = string.format("Terminal %d", i), terminal = i })
		end
	end
	return terminals
end

-- Telescope Picker

-- Telescope Picker for Open Terminals
local function open_terminal_picker()
	local terminals = get_open_terminals()
	if #terminals == 0 then
		print("No open terminals found.")
		return
	end
	pickers
		.new({}, {
			prompt_title = "Open Running Terminal",
			finder = finders.new_table({
				results = terminals,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name,
						ordinal = entry.name,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					open_terminal(selection.value)
				end)
				return true
			end,
		})
		:find()
end

-- Command to open the picker
vim.api.nvim_create_user_command("TelescopeCommands", open_command_picker, {})
vim.api.nvim_create_user_command("TelescopeOpenTerminals", open_terminal_picker, {})

function FindModifiedFile(suffix)
	local current_file = vim.fn.expand("%:p") -- Full path of the current file
	local file_name = vim.fn.expand("%:t:r") -- File name without extension
	local file_ext = vim.fn.expand("%:e") -- File extension
	local dir_path = vim.fn.expand("%:p:h") -- Directory path

	-- If it's a CoffeeScript file, find the templateUrl and open it
	if file_ext == "coffee" then
		local file = io.open(current_file, "r")
		if file then
			for line in file:lines() do
				local template_path = line:match('templateUrl:%s*"(.-)"')
				if template_path then
					local full_template_path = dir_path .. "/" .. template_path
					file:close() -- Close file before opening
					if vim.fn.filereadable(full_template_path) == 1 then
						vim.cmd("vsplit " .. vim.fn.fnameescape(full_template_path))
						return
					end
				end
			end
			file:close() -- Ensure file is closed if not found
		end
	end

	-- If it's index.html.haml, find component.js.coffee
	if file_name == "index" and vim.fn.expand("%:e:e") == "html.haml" then
		local target_file = dir_path .. "/component.js.coffee"
		if vim.fn.filereadable(target_file) == 1 then
			vim.cmd("vsplit " .. vim.fn.fnameescape(target_file))
			return
		end
	end

	-- Generic suffix-based lookup for other files
	if suffix and suffix ~= "" then
		-- Try file with suffix
		local target_file = dir_path .. "/" .. file_name .. suffix .. "." .. file_ext
		if vim.fn.filereadable(target_file) == 1 then
			vim.cmd("vsplit " .. vim.fn.fnameescape(target_file))
			return
		end

		-- Try removing suffix from filename
		local base_name = file_name:gsub(suffix .. "$", "")
		if base_name ~= file_name then -- Avoid unnecessary checks
			local original_file = dir_path .. "/" .. base_name .. "." .. file_ext
			if vim.fn.filereadable(original_file) == 1 then
				vim.cmd("vsplit " .. vim.fn.fnameescape(original_file))
				return
			end
		end
	end

	print("No corresponding file found.")
end

function FindTest()
	FindModifiedFile(".test")
end

function FindStories()
	FindModifiedFile(".stories")
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", {}),
	desc = "Hightlight selection on yank",
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 500 })
	end,
})

-- Keymaps
vim.keymap.set("n", "<leader>r", "<Plug>(SubversiveSubstitute)")

vim.keymap.set("n", "<leader>jl", ":8TermExec direction='float' cmd='jira issue list' open=1 <CR>")
vim.keymap.set("n", "<leader>yy", ":TelescopeCommands<CR>")

vim.keymap.set("n", "<leader>`", ":4ToggleTerm direction='float' <CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "to", ":lua FindTest()<CR>")
vim.keymap.set("n", "te", ":lua FindStories()<CR>")
vim.keymap.set("n", "<leader>fz", ":lua ZipnosisCommand()<CR>")
vim.keymap.set("n", "<leader>fr", ":lua FlorenceCommand()<CR>")
vim.keymap.set("n", "<leader>gf", ":lua FlorenceGrepCommand()<CR>")
vim.keymap.set("n", "<leader>gz", ":lua ZipnosisGrepCommand()<CR>")

vim.api.nvim_buf_set_keymap(
	0,
	"n",
	"<CR>",
	"<cmd>lua require('kulala').run()<cr>",
	{ noremap = true, silent = true, desc = "Execute the request" }
)
