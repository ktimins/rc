-- The C# stack (04-csharp-ide-nvim.md).
--
-- Static checks only: plugin presence, binaries, adapter wiring, key mappings.
-- A live Roslyn session takes 20+ seconds to load a solution, which is too slow
-- for a suite meant to be run often. See tests/README.md for the manual
-- verification steps that were run against a real two-project solution.

local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")
local T = H.new("csharp")

T.section("plugins present")
local lazycfg = require("lazy.core.config")
for _, name in ipairs({
   "roslyn.nvim", "blink.cmp", "friendly-snippets", "easy-dotnet.nvim",
   "nvim-dap", "nvim-dap-ui", "nvim-nio", "nvim-navic", "todo-comments.nvim",
}) do
   T.check(name, lazycfg.plugins[name] ~= nil, true)
end

T.section("server and tool binaries installed via Mason")
local ok_reg, reg = pcall(require, "mason-registry")
T.check("mason-registry loads", ok_reg, true)
if ok_reg then
   for _, pkg in ipairs({ "roslyn", "netcoredbg", "csharpier" }) do
      local ok_pkg, p = pcall(reg.get_package, pkg)
      T.check(pkg .. " installed", ok_pkg and p:is_installed(), true)
   end
end

T.section("netcoredbg is resolvable")
-- mason.setup() prepends its bin dir to PATH; without that the adapter command
-- resolves to an empty string and every launch fails with a confusing error
T.truthy("netcoredbg found on PATH", vim.fn.exepath("netcoredbg") ~= "")

T.section("dap adapter and configurations")
require("lazy").load({ plugins = { "nvim-dap" } })
local dap = require("dap")
T.check("coreclr adapter defined", dap.adapters.coreclr ~= nil, true)
if dap.adapters.coreclr then
   T.truthy("adapter points at a netcoredbg binary",
      (dap.adapters.coreclr.command or ""):lower():find("netcoredbg"))
   -- required on Windows: without it the debuggee console detaches and the
   -- session misbehaves
   T.check("options.detached is false",
      dap.adapters.coreclr.options and dap.adapters.coreclr.options.detached, false)
end

local names = {}
for _, c in ipairs(dap.configurations.cs or {}) do names[#names + 1] = c.name end
T.truthy("a launch configuration exists", vim.tbl_contains(names, "Launch DLL"))
T.truthy("an attach configuration exists", vim.tbl_contains(names, "Attach (pick process)"))

T.section("debug keymaps (provisional <leader>D..., F-keys undecided)")
for _, lhs in ipairs({ ",Dc", ",Db", ",Do", ",Di", ",DO", ",Du", ",Dt" }) do
   T.check("mapped " .. lhs, H.has_map("n", lhs), true)
end
-- The F-key collision with undotree/aerial is deliberately unresolved; these
-- must still belong to their doc 03 owners until that decision is made.
-- Assert on desc, not rhs: lazy.nvim installs callback stubs for `keys` specs,
-- so rhs is nil until the plugin actually loads.
T.check("<F9> still belongs to undotree",
   vim.fn.maparg("<F9>", "n", false, true).desc, "Undo tree")
T.check("<F10> still belongs to aerial",
   vim.fn.maparg("<F10>", "n", false, true).desc, "Symbol outline (was vista)")

T.section("formatting")
require("lazy").load({ plugins = { "conform.nvim" } })
local conform_ok, conform = pcall(require, "conform")
T.check("conform loads", conform_ok, true)
if conform_ok then
   local byft = conform.formatters_by_ft or {}
   T.truthy("csharpier registered for cs",
      byft.cs and vim.tbl_contains(byft.cs, "csharpier"))
   T.truthy("jq still registered for json", byft.json and vim.tbl_contains(byft.json, "jq"))
end
T.check("<leader>cf format mapping", H.has_map("n", ",cf"), true)

T.section("exactly one Roslyn client owns completion")
-- easy-dotnet ships its own Roslyn LSP layer, enabled by default. With both it
-- and roslyn.nvim active, each answers textDocument/completion with identical
-- results and every C# completion appears twice. Verified on a real solution:
-- roslyn returned 5 items, easy_dotnet returned the same 5.
local ed_ok, ed_opts = pcall(function()
   require("lazy").load({ plugins = { "easy-dotnet.nvim" } })
   return require("easy-dotnet.options").options
end)
if ed_ok and ed_opts then
   T.check("easy-dotnet's own LSP is disabled",
      ed_opts.lsp and ed_opts.lsp.enabled, false)
else
   T.check("easy-dotnet options readable", ed_ok, true)
end

T.finish()
