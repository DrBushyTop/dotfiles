require("catppuccin").setup({
  flavour = "macchiato",
  custom_highlights = function(colors)
    return {
      Comment = { fg = colors.yellow },
      ["@comment"] = { fg = colors.yellow, style = { "italic" } },
      CursorLineNr = { fg = colors.yellow },
      LineNr = { fg = colors.yellow },
    }
  end,
})

return {
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
  },

  -- Configure LazyVim to load catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
