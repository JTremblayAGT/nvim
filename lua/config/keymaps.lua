-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Remove default hjkl mappings
vim.keymap.del({"n", "x"}, "j")
vim.keymap.del({"n", "x"}, "k")
vim.keymap.del({"n", "i", "v"}, "<A-j>")
vim.keymap.del({"n", "i", "v"}, "<A-k>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Right>")
vim.keymap.del("n", "H")

-- Remap movement keys to jkl;
vim.keymap.set({"n", "x", "v"}, ";", "l", { desc = "Move right" })
vim.keymap.set({"n", "x", "v"}, "l", "k", { desc = "Move up" })
vim.keymap.set({"n", "x", "v"}, "k", "j", { desc = "Move down" })
vim.keymap.set({"n", "x", "v"}, "j", "h", { desc = "Move left" })

vim.keymap.set({"n", "x", "v"}, "L", "10k", { desc = "Move up" })
vim.keymap.set({"n", "x", "v"}, "K", "10j", { desc = "Move down" })

vim.keymap.set("n", "<C-Left>" , "<C-w>h", { desc = "Go to Left Window", remap = true })
vim.keymap.set("n", "<C-Down>" , "<C-w>j", { desc = "Go to Lower Window", remap = true })
vim.keymap.set("n", "<C-Up>"   , "<C-w>k", { desc = "Go to Upper Window", remap = true })
vim.keymap.set("n", "<C-Right>", "<C-w>l", { desc = "Go to Right Window", remap = true })

vim.keymap.set("n", "<C-S-Up>"   , "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-S-Down>" , "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-S-Left>" , "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

vim.keymap.set("n", "<C-A-Up>"   , "<C-w>H", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-A-Down>" , "<C-w>J", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-A-Left>" , "<C-w>K", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-A-Right>", "<C-w>L", { desc = "Increase Window Width" })

vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-l>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<A-l>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-l>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

vim.keymap.set("n", "o", "o<esc>", { desc = "Stay in normal after newline", remap = true})
vim.keymap.set("n", "O", "O<esc>", { desc = "Stay in normal after newline", remap = true})

vim.keymap.set("n", "U", "<C-r>", { desc = "Redo", remap = true})