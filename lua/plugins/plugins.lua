return {
  { "simonl91/fanuc-karel-diagnostics.nvim" },
  { "KnoP-01/vim-tp" },
  { "wannesm/wmnusmv.vim" },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", has = "definition" },
            { "H", "<cmd>lua vim.lsp.buf.hover()<CR>", has = "definition" },
            { "K", false },
          },
        },
        fanuctp = {
          -- server opts here
        },
      },
      setup = {
        fanuctp = function(_, opts)
          local lspconfig = require("lspconfig")
          local configs = require("lspconfig.configs")
          local util = require("lspconfig.util")

          if not configs.fanuctp then
            configs.fanuctp = {
              default_config = {
                cmd = {
                  "FanucLSP.exe",
                },
                filetypes = {
                  "tp",
                  "karel",
                },
                single_file_support = true,
                root_dir = util.root_pattern(".git", "."),
                settings = {
                  -- default settings here
                },
              },
              commands = {},
              docs = {
                description = [[ 
                ]],
              },
            }
          end
          lspconfig.fanuctp.setup(opts)
        end,
      },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "saadparwaiz1/cmp_luasnip" },
    opts = {
      snippets = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip" },
      },
    },
  },
}
