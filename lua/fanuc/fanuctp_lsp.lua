local lspconfig = require("lspconfig")

return {
  default_config = {
    cmd = { "C:\\Users\\justin.tremblay\\Projects\\fanuctp-lsp\\FanucTpLSP\\bin\\Debug\\net9.0\\FanucTpLSP.exe" },
    filetypes = { "ls" },
    root_dir = lspconfig.util.root_pattern(".git", "."),
  },
}
