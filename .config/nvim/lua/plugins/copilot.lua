return {
  {
    "zbirenbaum/copilot.lua",
    lazy = false,
    cmd = "Copilot",
    build = ":Copilot auth",
    config = function()
      require("copilot").setup({
        panel = { enabled = true },
        suggestion = {
          enabled = true,
          auto_trigger = true,
        },
        filetypes = {
          ["."] = true,
        },
      })
    end,
  },
}
