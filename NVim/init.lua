-- Neovim configuration entry point.
--
-- This file lives in the rc repo at NVim/. %LOCALAPPDATA%\nvim is a directory
-- junction pointing here, so Neovim loads the repo copy directly. See README.md
-- in this folder for the junction command.
--
-- Design docs: Vim/vimrc/nvim-migration/ in this repo. Implementation order is
-- fixed: colemak (doc 01) is verified before anything else is built on top.
--
-- Deliberately separate from the gVim setup in Vim/. The two are independent
-- systems and share no files.

-- Load marker: proves this file, and not some other init, was loaded.
vim.g.rc_nvim_loaded = true

-- Colemak first, before anything that could fail. The keyboard contract has to
-- hold even if every other part of this config errors out.
require("colemak").setup()

require("machine")   -- $LOCATION -> user/home/rc_repo paths, sets _G.Machine
require("options")   -- sets mapleader, so it must precede anything using it
require("keymaps")
require("autocmds")
require("functions")
require("gui")       -- no-op outside Neovide

require("config.lazy") -- plugins last: everything above must hold without them
