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
{ 
    "folke/neoconf.nvim", 
    cmd = "Neoconf" 
},
"folke/neodev.nvim",
"shaunsingh/nord.nvim",
'github/copilot.vim',
{    "tpope/vim-fugitive",
      config = function()
	vim.keymap.set('n', '<leader>gs', ':Git<CR>', {})
	vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', {})
	vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', {})
	vim.keymap.set('n', '<leader>gd', ':Gdiffsplit<CR>', {})
	vim.keymap.set('n', '<leader>gl', ':Glog<CR>', {})
	vim.keymap.set('n', '<leader>gp', ':Git push<CR>', {})
	vim.keymap.set('n', '<leader>gr', ':Gread<CR>', {})
	vim.keymap.set('n', '<leader>gw', ':Gwrite<CR>', {})
	vim.keymap.set('n', '<leader>gj', ':diffget //3<CR>', {})
	vim.keymap.set('n', '<leader>gk', ':diffget //2<CR>', {})
      end

},
'metakirby5/codi.vim',
'svermeulen/vim-subversive',
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
{
     "VonHeikemen/lsp-zero.nvim",
     config = function()
       require("lsp-zero").setup()
       local lsp_zero = require('lsp-zero')

       lsp_zero.on_attach(function(client, bufnr)
  	lsp_zero.default_keymaps({buffer = bufnr})
       end)
     end
},

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
}
})

-- settings
vim.cmd[[colorscheme tokyonight-storm]]
vim.opt.number = true
vim.opt.termguicolors = true

-- keybindings
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
