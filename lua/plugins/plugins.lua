return {
    {"simonl91/fanuc-karel-diagnostics.nvim"},
    {"KnoP-01/vim-tp" },
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local keys = require("lazyvim.plugins.lsp.keymaps").get()
            keys[#keys + 1] = { "K", false }
            keys[#keys + 1] = { "H", function() return vim.lsp.buf.hover() end }
        end,
    }
}