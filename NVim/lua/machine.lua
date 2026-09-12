-- Per-machine resolution, driven by the $LOCATION environment variable.
--
-- The old _vimrc hardcoded home, storage and plug-file paths per machine.
-- Neovim's stdpath() removes almost all of that; what stays worth knowing is
-- which user this machine runs as, so paths into the rc repo can be built for
-- dashboard bookmarks and shared files.

local location = (vim.env.LOCATION or ""):upper()
local users = { WORK = "ktimins", THEIA = "rzite", ARES = "rzitex" }
local user = users[location]

local M = {
   location = location,
   home = user and ("C:/Users/" .. user) or vim.fn.expand("~"),
}
M.rc_repo = M.home .. "/Git/rc"

-- Convenient global so plugin specs can reference paths without requiring this
-- module in every file.
_G.Machine = M

return M
