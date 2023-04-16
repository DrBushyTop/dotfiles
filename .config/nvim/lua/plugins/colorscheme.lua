require("catppuccin").setup({
  flavour = "macchiato",
  custom_highlights = function(colors)
    return {
      Comment = { fg = colors.yellow },
      ["@comment"] = { fg = colors.yellow, style = { "italic" } },
    }
  end,
})

return {
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
  },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
