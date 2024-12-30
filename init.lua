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
require("lazy").setup({
	"folke/which-key.nvim",
	"kchmck/vim-coffee-script",
	"folke/neodev.nvim",
	"shaunsingh/nord.nvim",
	"justinmk/vim-sneak",
	"github/copilot.vim",
	"metakirby5/codi.vim",
	"svermeulen/vim-subversive",
	-- { "glacambre/firenvim", build = ":call firenvim#install(0)" },
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
			vim.keymap.set("n", "<leader>ca", ":CodeCompanion<CR>", {})
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
					typescript = { { "prettierd" } },
					json = { { "prettierd" } },
					typescriptreact = { { "prettierd" } },
					javascript = { { "prettierd" } },
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
		opts = {},
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		config = function()
			local noice = require("noice")
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
			vim.keymap.set("n", "<leader>n", ":Neotree toggle<CR>", {})
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

-- keybindings
function FindModifiedFile(suffix)
	-- Get the base name of the current file (without path)
	local fileName = vim.fn.expand("%:t:r")
	-- Get the full extension of the current file
	local fullExt = vim.fn.expand("%:e")
	local baseExt = vim.fn.expand("%:r:e") -- Extension before the last dot

	-- Special handling for index.html.haml <-> component.js.coffee
	local targetFileName
	if fullExt == "haml" and baseExt == "html" and fileName == "index" then
		-- Convert index.html.haml to component.js.coffee
		targetFileName = "component.js.coffee"
	elseif fullExt == "coffee" and baseExt == "js" and fileName == "component" then
		-- Convert component.js.coffee to index.html.haml
		targetFileName = "index.html.haml"
	elseif (fullExt == "coffee" or fullExt == "haml") and suffix == ".stories" then
		-- Exclude adding `.stories` for .coffee or .haml files
		targetFileName = fileName .. "." .. fullExt
	elseif (fullExt == "coffee" or fullExt == "haml") and suffix == ".test" then
		-- Convert `.test` to `.spec` for .coffee or .haml files
		targetFileName = fileName .. ".spec." .. fullExt
	else
		-- Handle generic suffix logic
		if fileName:sub(-#suffix) == suffix then
			-- If the file contains the suffix, remove it and search for the original file
			targetFileName = fileName:sub(1, -#suffix - 1) .. "." .. fullExt
		else
			-- If the file does not contain the suffix, add it
			targetFileName = fileName .. suffix .. "." .. fullExt
		end
	end

	-- Use the 'rg' command to search for the file in the current directory
	local cmd = "rg --files | grep '" .. targetFileName .. "'"
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()

	-- Split the result into lines (file paths)
	local files = {}
	for file in result:gmatch("[^\r\n]+") do
		table.insert(files, file)
	end

	-- If no files were found, print a message and return
	if #files == 0 then
		print("No file found for '" .. targetFileName .. "'")
		return
	end

	-- Open the first file found in a vertical split
	vim.cmd("vsplit " .. files[1])
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
vim.keymap.set(
	"n",
	"<leader>yy",
	":1TermExec direction='float' cmd='cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx dev' open=0 <CR>"
)
vim.keymap.set(
	"n",
	"<leader>ys",
	":2TermExec direction='float' cmd='cd ~/gitstuff/florence-fe && nx storybook virtual-care' open=0 <CR>"
)
vim.keymap.set(
	"n",
	"<leader>yn",
	":3TermExec direction='float' cmd='cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx nginx' open=0 <CR>"
)
vim.keymap.set("n", "<leader>`", ":ToggleTerm direction='float' <CR>")
vim.keymap.set(
	"n",
	"<leader>yn",
	":4TermExec direction='float' cmd='cd ~/gitstuff/florence-fe/apps/virtual-care/ && nx nginx' open=0 <CR>"
)
vim.keymap.set(
	"n",
	"<leader>yt",
	":5TermExec direction='float' cmd='cd ~/gitstuff/florence-fe/apps/virtual-care/ &&  nx test' open=1 <CR>"
)
vim.keymap.set(
	"n",
	"<leader>yr",
	":6TermExec direction='float' cmd='cd ~/gitstuff/florence-fe/apps/virtual-care/ &&  nx test-storybook' open=1 <CR>"
)
vim.keymap.set(
	"n",
	"<leader>yl",
	":7TermExec direction='float' cmd='cd ~/gitstuff/florence-fe/apps/virtual-care/ &&  nx lint' open=1 <CR>"
)

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
