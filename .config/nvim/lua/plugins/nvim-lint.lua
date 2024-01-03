return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      go = { "golangcilint" },
      -- lua = { "luacheck" },
      markdown = { "markdownlint" },
      -- json = { "jsonlint" },
      -- yaml = { "yamllint" },
      zsh = { "zsh" },
      html = { "tidy" },
      templ = { "tidy" },
    },
  },
}
