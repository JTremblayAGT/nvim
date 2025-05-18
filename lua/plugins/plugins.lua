return {
  { "simonl91/fanuc-karel-diagnostics.nvim" },
  { "KnoP-01/vim-tp" },
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "K", false }
      keys[#keys + 1] = {
        "H",
        function()
          return vim.lsp.buf.hover()
        end,
      }
      return {
        --inlay_hints = { enabled = false },
        servers = {
          fanuctp_lsp = {},
        },
        setup = {
          fanuctp_lsp = function(_, opts)
            opts.on_attach = function(client, bufnr)
              require("lsp_signature").on_attach({
                bind = true,
                handler_opts = { border = "rounded" },
              }, bufnr)
            end
          end,
        },
      }
    end,
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
}
