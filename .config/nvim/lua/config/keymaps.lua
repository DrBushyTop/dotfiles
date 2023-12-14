-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/lazyvim/lazyvim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- This file is automatically loaded by lazyvim.config.init
local Util = require("lazyvim.util")

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    if opts.remap and not vim.g.vscode then
      opts.remap = nil
    end
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- Copying lines up and down in visual mode
vim.keymap.set("v", "<A-S-j>", ":t '>+1<cr>gv=gv", { desc = "Copy down" })
vim.keymap.set("v", "<A-S-k>", ":t '<-2<cr>gv=gv", { desc = "Copy up" })

-- VS Code like Ctrl D multiselect replace
vim.keymap.set("n", "<A-S-d>", "*Ncgn", { desc = "Multiselect replace" })
-- kj and jk to escape insert mode
vim.keymap.set("i", "kj", "<esc>", { desc = "Escape insert mode" })
vim.keymap.set("i", "jk", "<esc>", { desc = "Escape insert mode" })
