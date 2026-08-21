-- Plugin-layer verification (03-plugins.md section 6).
--
-- Checks that every declared plugin installed cleanly, that the F-key muscle
-- memory carried over, and that treesitter actually attaches to a C# buffer,
-- which is the whole point of the parser set.

local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")
local T = H.new("plugins")

T.section("lazy state")
local ok_cfg, lazycfg = pcall(require, "lazy.core.config")
T.check("lazy.nvim loaded", ok_cfg, true)

if ok_cfg then
   local total, errored = 0, {}
   for name, p in pairs(lazycfg.plugins) do
      total = total + 1
      if p._ and p._.has_errors then
         errored[#errored + 1] = name
      end
   end
   T.truthy("plugins declared (" .. total .. ")", total > 30)
   T.check("no plugin reported errors", errored, {})
end

T.section("no stale clone markers")
-- lazy writes <plugin>.cloning before cloning and removes it after. A leftover
-- marker means the clone failed and the plugin will be re-cloned on EVERY
-- startup. rainbow-delimiters hit this: a gitlab-hosted submodule returns 403
-- on this network, which is why its spec sets submodules = false.
local markers = vim.fn.glob(vim.fn.stdpath("data") .. "/lazy/*.cloning", false, true)
T.check("no .cloning leftovers", markers, {})

T.section("key mappings survived the plugin set")
for _, spec in ipairs({
   { "<F7>", "buffers picker" },
   { "<F8>", "file tree" },
   { "<F9>", "undo tree" },
   { "<F10>", "symbol outline" },
   { "<C-N>", "file tree" },
   { ",bc", "close buffer keep layout" },
   { ",z", "zen mode" },
   { ",ff", "find files" },
   { ",fg", "live grep" },
   { ",qs", "restore session" },
}) do
   T.check(string.format("%s (%s)", spec[1], spec[2]),
      vim.fn.maparg(spec[1], "n") ~= "", true)
end

T.section("treesitter")
local ok_ts, tscfg = pcall(require, "nvim-treesitter.config")
T.check("nvim-treesitter loaded", ok_ts, true)

if ok_ts then
   local installed = {}
   for _, p in ipairs(select(2, pcall(tscfg.get_installed, "parsers")) or {}) do
      installed[p] = true
   end
   -- c_sharp is the one that matters; the rest replace the old syntax packs
   for _, p in ipairs({ "c_sharp", "lua", "json", "xml", "markdown", "python" }) do
      T.check("parser installed: " .. p, installed[p] == true, true)
   end
end

T.section("treesitter attaches to a C# buffer")
local dir = H.tempdir()
local cs = dir .. "/Probe.cs"
vim.fn.writefile({
   "namespace Demo",
   "{",
   "    public class Thing",
   "    {",
   "        public int Value { get; set; }",
   "    }",
   "}",
}, cs)
vim.cmd("edit " .. cs)
T.check("filetype is cs", vim.bo.filetype, "cs")
T.check("a parser attaches", (pcall(vim.treesitter.get_parser, 0)), true)
T.check("highlighting is active",
   vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, true)

T.section("vimwiki does not hijack every markdown file")
-- vimwiki's ext2syntax claims .md globally by default, making every markdown
-- file on the machine filetype=vimwiki. That silently disables markdown
-- treesitter highlighting, markdown-preview (ft="markdown"), conform, and the
-- ltex grammar server, none of which announce themselves when they fail to
-- attach. g:vimwiki_global_ext = 0 scopes vimwiki to its own directory.
for _, ext in ipairs({ "md", "markdown" }) do
   local f = string.format("%s/note.%s", dir, ext)
   vim.fn.writefile({ "# heading" }, f)
   vim.cmd("edit! " .. vim.fn.fnameescape(f))
   T.check("." .. ext .. " outside ~/vimwiki is markdown", vim.bo.filetype, "markdown")
end

T.section("grammar checking is wired")
T.check("ltex_plus LSP config registered", vim.lsp.config["ltex_plus"] ~= nil, true)
local ok_reg, reg = pcall(require, "mason-registry")
if ok_reg then
   local ok_pkg, pkg = pcall(reg.get_package, "ltex-ls-plus")
   T.check("ltex-ls-plus installed via Mason", ok_pkg and pkg:is_installed(), true)
end
-- vim-LanguageTool must stay gone: it drives the LanguageTool CLI with --api,
-- which LanguageTool 6.x removed.
T.check("vim-LanguageTool is not installed",
   lazycfg and lazycfg.plugins["vim-LanguageTool"] == nil, true)

T.section("xsd and xaml resolve to the xml parser")
for _, ext in ipairs({ "xsd", "xaml" }) do
   local f = string.format("%s/probe.%s", dir, ext)
   vim.fn.writefile({ "<root><child/></root>" }, f)
   vim.cmd("edit " .. f)
   T.check(ext .. " gets a parser", (pcall(vim.treesitter.get_parser, 0)), true)
end

T.finish()
