return {
  -- add stuff to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- will be automatically installed with mason and loaded with lspconfig
        bashls = {},
        powershell_es = {},
        csharp_ls = {},
        bicep = {},
        jsonls = {},
        yamlls = {},
        golangci_lint = {},
        gopls = {},
        sql = {},
      },
    },
  },
}
