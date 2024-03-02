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
"folke/neodev.nvim",
"shaunsingh/nord.nvim",
'github/copilot.vim',
'metakirby5/codi.vim',
'svermeulen/vim-subversive',
{ 
    "folke/neoconf.nvim", 
    cmd = "Neoconf" 
},

{    
    "tpope/vim-fugitive",
     config = function()
       vim.keymap.set('n', '<leader>gs', ':Git<CR>', {})
       vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', {})
       vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', {})
       vim.keymap.set('n', '<leader>gp', ':Git push<CR>', {})
     end
},
{
    'akinsho/toggleterm.nvim', 
    version = "*", 
    config = true
    
},
{
    "kylechui/nvim-surround",
    version = "*", 
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({})
    end
},
{
    "numToStr/Comment.nvim",
    lazy = false,
    config = function()
        require('Comment').setup()
    end
},
{
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function () 
      local configs = require("nvim-treesitter.configs")

      configs.setup({
          ensure_installed = { "ruby", "lua", "vim", "vimdoc", "javascript", "html", 'css', 'typescript', 'tsx', 'xml' },
          sync_install = false,
          highlight = { enable = true },
          indent = { enable = true },  
      })
    end
 },
 {
     'nvim-lualine/lualine.nvim',
     dependencies = { 'nvim-tree/nvim-web-devicons' },
     config = function()

       local colors = {
         blue   = '#80a0ff',
         cyan   = '#79dac8',
         black  = '#080808',
         white  = '#c6c6c6',
         red    = '#ff5189',
         violet = '#d183e8',
         grey   = '#303030',
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
       require('lualine').setup({
         options = {
           theme = bubbles_theme,
            component_separators = '|',
            section_separators = { left = '', right = '' },
          },
          sections = {
            lualine_a = {
              { 'mode', separator = { left = '' }, right_padding = 2 },
            },
            lualine_b = { 'filename', 'branch' },
            lualine_c = { 'fileformat' },
            lualine_x = {}  ,
            lualine_y = { 'filetype', 'progress' },
            lualine_z = {
              { 'location', separator = { right = '' }, left_padding = 2 },
            },
          },
          inactive_sections = {
          lualine_a = { 'filename' },
          lualine_b = {},
	    lualine_c = {},
	    lualine_x = {},
	    lualine_y = {},
	    lualine_z = { 'location' },
	    },
	    tabline = {},
	    extensions = {}
	  })
      end
},
{
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
      dependencies = { 'nvim-lua/plenary.nvim' },

     config = function()
       local builtin = require('telescope.builtin')
       vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
       vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
       vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
       vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
     end
},
{
     "nvim-neotest/neotest",
     opts = { adapters = { "neotest-plenary","neotest-jest", "neotest-playwright" }},
     status = { virtual_text = true },
     output = { open_on_run = true },
     config = function()

       require("neotest").setup({})
       vim.keymap.set('n', '<leader>tf', ':Neotest run file<CR>', {})
     end
},
{
     "folke/noice.nvim",
      event = "VeryLazy",
      opts = {},
      dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
      }
},
     "VonHeikemen/lsp-zero.nvim",
{
      "williamboman/mason.nvim",
      dependencies ={ "williamboman/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },

      config = function()
       local lsp_zero = require('lsp-zero')
        require("mason").setup()
        require("mason-lspconfig").setup({
	  ensure_installed = {},
	  handlers = {
            lsp_zero.default_setup,

          },
	})


       lsp_zero.on_attach(function(client, bufnr)
	local buf = {buffer = bufnr}
  	lsp_zero.default_keymaps(buf)
	 vim.keymap.set('n', '<leader>ar', '<cmd>lua vim.lsp.buf.rename()<cr>', buf)
	 vim.keymap.set('n', '<leader>aw', '<cmd>lua vim.lsp.buf.code_action()<cr>', buf)
	 vim.keymap.set('n', '<leader>p', '<cmd>lua vim.lsp.buf.format({async = true})<cr', buf)
       end)
      end
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
        vim.keymap.set('n', '<leader>n', ':Neotree toggle<CR>', {})
      end
},
{
    "folke/trouble.nvim",
     dependencies = {"nvim-tree/nvim-web-devicons"},
     opts = {}

},
{
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
},
{
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
  --   "BufReadPre path/to/my-vault/**.md",
  --   "BufNewFile path/to/my-vault/**.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/vaults/personal",
      },
      {
        name = "work",
        path = "~/vaults/work",
      },
    },
  },
}

})

-- settings
vim.cmd[[colorscheme tokyonight-storm]]
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.cursorline = true

-- keybindings
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("n", "<leader>ar", "")
vim.keymap.set("n", "<leader>yy", ":ToggleTerm direction='float' cmd='yarn start' <CR>")
vim.keymap.set("n", "<leader>ys", ":ToggleTerm direction='float' cmd='yarn storybook' <CR>")
