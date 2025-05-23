return {
  { "simonl91/fanuc-karel-diagnostics.nvim" },
  { "KnoP-01/vim-tp" },
  {
    "neovim/nvim-lspconfig",
    keys = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "K", false }
      keys[#keys + 1] = {
        "H",
        function()
          return vim.lsp.buf.hover()
        end,
      }
    end,
    opts = {
      servers = {
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
                  "FanucTpLSP.exe",
                },
                filetypes = {
                  "tp",
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
