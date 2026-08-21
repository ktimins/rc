-- Global mappings ported from _vimrc.
--
-- Leader is ','. Mappings that belong to a plugin live with that plugin's spec,
-- and filetype-local mappings live in autocmds.lua, so this file is only the
-- editor-wide ones.

local map = vim.keymap.set

-- clear search highlight
map("n", "<leader><cr>", "<cmd>nohlsearch<cr>", { silent = true })
map("n", "<leader>n", "<cmd>nohlsearch<cr>")

-- window navigation without the <C-w> prefix
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")

-- buffers. <leader>bc is deliberately absent: it needs a delete that preserves
-- the window layout, which arrives with the bufdelete plugin. The old _vimrc
-- pointed it at :Bclose, a command that was never defined anywhere.
map("n", "<leader>bd", "<cmd>bdelete<cr>")
map("n", "<leader>ba", "<cmd>bufdo bd<cr>")
map("n", "<leader>bn", "<cmd>bnext<cr>")
map("n", "<leader>bp", "<cmd>bprev<cr>")

-- cwd to the current file's directory
map("n", "<leader>cd", "<cmd>cd %:p:h<cr><cmd>pwd<cr>")

-- spelling
map("n", "<leader>ss", "<cmd>setlocal spell!<cr>")
map("n", "<leader>sn", "]s")
map("n", "<leader>sp", "[s")
map("n", "<leader>sa", "zg")
map("n", "<leader>s?", "z=")

-- strip stray carriage returns when an encoding goes wrong (verbatim port:
-- <C-V><cr> puts a literal CR into the pattern)
map("n", "<leader>m", "mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm")

-- scribble buffers
map("n", "<leader>q", "<cmd>e ~/buffer<cr>")
map("n", "<leader>x", "<cmd>e ~/buffer.md<cr>")

-- visual * and # search for the selected text. The old _vimrc called
-- VisualSelection('', ''), a function defined nowhere, so this has been broken
-- for years; this is the standard escape-safe idiom instead.
map("x", "*", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])
map("x", "#", [[y?\V<C-R>=escape(@",'?\')<CR><CR>]])
