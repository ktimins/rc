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
   for _, pkg in ipairs({ "netcoredbg", "csharpier" }) do
      local ok_pkg, p = pcall(reg.get_package, pkg)
      T.check(pkg .. " installed", ok_pkg and p:is_installed(), true)
   end
end

T.section("the Roslyn server is reachable")
-- Deliberately NOT asserting a Mason package name. Two packages provide this
-- server: `roslyn` from the Crashdummyy registry and `roslyn-language-server`
-- from mason-org. Both create the same bin, both satisfy roslyn.nvim, and
-- which one is installed is a machine-level choice, not an invariant.
--
-- What must be true is that roslyn.nvim can resolve a server it can actually
-- run. get_roslyn_lsp_path() tries the Mason bin, then PATH, then falls back to
-- returning a bare name that need not exist -- so the resolved path has to be
-- checked for executability or the fallback passes silently.
require("lazy").load({ plugins = { "roslyn.nvim" } })
local ok_utils, utils = pcall(require, "roslyn.utils")
T.check("roslyn.utils loads", ok_utils, true)
if ok_utils then
   local server = utils.get_roslyn_lsp_path()
   T.truthy("roslyn server resolves to an executable: " .. server, vim.fn.executable(server) == 1)
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

T.section("build to quickfix")
local dir = H.tempdir()
local cs = dir .. "/Probe.cs"
vim.fn.writefile({ "class Probe {}" }, cs)
vim.cmd("edit! " .. vim.fn.fnameescape(cs))
T.check("makeprg builds the solution", vim.bo.makeprg, "dotnet build --nologo")
T.truthy("errorformat handles MSBuild diagnostics", vim.bo.errorformat:find("%%trror"))

-- Parse a real MSBuild diagnostic rather than trusting the pattern by eye. A
-- wrong errorformat yields an empty quickfix, which is indistinguishable from
-- a clean build.
vim.fn.setqflist({}, " ", {
   -- [==[ ]==] because the sample lines end in "]", which would close a plain
   -- [[ ]] bracket early
   lines = {
      [==[C:\proj\Foo.cs(12,5): error CS1002: ; expected [C:\proj\Proj.csproj]]==],
      [==[C:\proj\Bar.cs(3,1): warning CS0168: unused variable [C:\proj\Proj.csproj]]==],
   },
   efm = vim.bo.errorformat,
})
local qf = vim.fn.getqflist()
local valid, kinds = 0, {}
for _, e in ipairs(qf) do
   if e.valid == 1 then
      valid = valid + 1
      kinds[#kinds + 1] = e.type
   end
end
T.check("both diagnostics parse", valid, 2)
T.check("severities are error and warning", kinds, { "e", "w" })
T.check("line and column survive", { qf[1].lnum, qf[1].col }, { 12, 5 })

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
