return {
  "stevearc/conform.nvim",
  opts = function()
    ---@class ConformOpts
    local opts = {
      -- LazyVim will use these options when formatting with the conform.nvim formatter
      format = {
        timeout_ms = 3000,
        async = false, -- not recommended to change
        quiet = false, -- not recommended to change
      },
      ---@type table<string, conform.FormatterUnit[]>
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        go = { "goimports", "golines", "gofmt" },
        markdown = { "cbfmt", "mdformat" },
        json = { "fixjson" },
        yaml = { "yamlfix" },
        zsh = { "shfmt" },
        html = { "tidy" },
        templ = { "templ" },
      },
    }

    return opts
  end,
}
