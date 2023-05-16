return {
  -- add stuff to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- will be automatically installed with mason and loaded with lspconfig
        bashls = {
          filetypes = { "sh", "zsh" },
        },
        powershell_es = {},
        csharp_ls = {},
        bicep = {},
        jsonls = {},
        yamlls = {},
        lua_ls = {},
        gopls = {},
      },
    },
  },
}
