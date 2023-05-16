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
          debounce = 75,
          keymap = {
            accept = false,
            accept_word = "<M-,>",
            accept_line = "<M-.>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        filetypes = {
          ["."] = true,
        },
      })

      local keymap_accept = "<Tab>"
      local keycode = vim.api.nvim_replace_termcodes(keymap_accept, true, false, true)
      local suggestion = require("copilot.suggestion")
      local luasnip = require("luasnip")
      local function accept()
        if luasnip.expand_or_jumpable() then
          luasnip.jump_or_expand()
        elseif suggestion.is_visible() then
          suggestion.accept()
        else
          vim.api.nvim_feedkeys(keycode, "n", false)
        end
      end
      vim.keymap.set("i", keymap_accept, accept, { remap = false, silent = true })
    end,
  },
}
