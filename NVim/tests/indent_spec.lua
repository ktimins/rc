-- Indentation, which is the area of this config that has produced the most
-- silent breakage.
--
-- Two failure modes this guards against:
--   1. Handing a filetype to treesitter when it has no indents.scm. The
--      expression then returns 0 for every line, and because 'indentexpr'
--      overrules both 'cindent' and 'smartindent', the buffer loses auto-indent
--      entirely and `gg=G` flattens it. c_sharp is exactly this case.
--   2. Leaving a filetype on a built-in that does not actually work. XmlIndentGet
--      is a no-op here, which went unnoticed because a flat file looks like a
--      file nobody reindented.

local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")
local T = H.new("indent")

local dir = H.tempdir()

local function open(name, lines)
   local f = dir .. "/" .. name
   vim.fn.writefile(lines, f)
   vim.cmd("edit! " .. f)
   return f
end

local function reindent(name, lines)
   open(name, lines)
   vim.cmd("normal! gg=G")
   return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local TS = "v:lua.require'nvim-treesitter'.indentexpr()"

T.section("each filetype uses the intended indent method")
for _, case in ipairs({
   { "probe.cs", "GetCSIndent(v:lnum)", "C# keeps Neovim's bundled indent (no indents.scm)" },
   { "probe.html", "HtmlIndent()", "html keeps the built-in (ties with treesitter)" },
   { "probe.xml", TS, "xml uses treesitter (built-in is a no-op)" },
   { "probe.xsd", TS, "xsd uses treesitter" },
   { "probe.xaml", TS, "xaml uses treesitter (was falling through to cindent)" },
   { "probe.ps1", TS, "ps1 uses treesitter (was falling through to cindent)" },
   { "probe.json", TS, "json uses treesitter" },
   { "probe.py", TS, "python uses treesitter" },
}) do
   open(case[1], { "" })
   T.check(case[3], vim.bo.indentexpr, case[2])
end

T.section("C# actually indents (regression: indentexpr returning 0 flattened it)")
T.check("nested braces indent by shiftwidth", reindent("T.cs", {
   "namespace N",
   "{",
   "public class C",
   "{",
   "public void M()",
   "{",
   "int x = 1;",
   "}",
   "}",
   "}",
}), {
   "namespace N",
   "{",
   "   public class C",
   "   {",
   "      public void M()",
   "      {",
   "         int x = 1;",
   "      }",
   "   }",
   "}",
})

T.section("XML nests instead of staying flat")
T.check("elements nest by shiftwidth", reindent("T.xml", {
   "<configuration>",
   "<appSettings>",
   '<add key="a" value="1"/>',
   "</appSettings>",
   "</configuration>",
}), {
   "<configuration>",
   "  <appSettings>",
   '    <add key="a" value="1"/>',
   "  </appSettings>",
   "</configuration>",
})

T.section("XAML nests")
T.check("nested elements indent", reindent("T.xaml", {
   '<Window xmlns="http://x">',
   "<Grid>",
   '<Button Content="Hi"/>',
   "</Grid>",
   "</Window>",
}), {
   '<Window xmlns="http://x">',
   "  <Grid>",
   '    <Button Content="Hi"/>',
   "  </Grid>",
   "</Window>",
})

T.section("PowerShell blocks indent")
-- Deliberately does NOT cover `param(...)`: treesitter's powershell query does
-- not indent it. That is a known gap, still far better than cindent, which
-- mis-indented the whole if/else cascade below.
local ps = reindent("T.ps1", {
   "if ($Name) {",
   "Write-Output $Name",
   "} else {",
   'Write-Output "none"',
   "}",
})
T.check("if/else body indents by shiftwidth", ps, {
   "if ($Name) {",
   "   Write-Output $Name",
   "} else {",
   '   Write-Output "none"',
   "}",
})

T.finish()
