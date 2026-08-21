-- Treesitter, editing behavior, formatting, and the plugins carried over from
-- _vimrc.plug that still earn their place.

-- Parsers to keep installed. c_sharp is the one that matters most; the rest
-- replace the vim-polyglot / vim-csharp / vim-ps1 / html5 / vim-json syntax
-- packs with real parsers.
local PARSERS = {
   "c_sharp", "lua", "vim", "vimdoc", "json", "xml", "html", "css",
   "markdown", "markdown_inline", "python", "sql", "powershell",
   "javascript", "yaml", "regex", "diff", "gitcommit",
}

-- Filetypes that should get treesitter highlighting, matching the parsers above.
local TS_FILETYPES = {
   "cs", "lua", "vim", "help", "json", "xml", "xsd", "xaml", "html", "css",
   "markdown", "python", "sql", "ps1", "javascript", "yaml", "diff", "gitcommit",
}

-- Filetypes that keep their existing indent method instead of treesitter's.
--
-- Only html, and only because it earns it: HtmlIndent and treesitter produce
-- byte-identical output on test input, and the built-in has years of handling
-- embedded <script>/<style>. No reason to move a tie.
--
-- Everything else was measured and moved:
--   xml, xsd  XmlIndentGet is a NO-OP here; `gg=G` left files completely flat
--   xaml, ps1 no runtime indent plugin at all, so both fell through to
--             'cindent', i.e. C-style brace indenting applied to XML and
--             PowerShell. Treesitter is not perfect on ps1 (it misses `param`
--             blocks) but cindent mis-indented the entire if/else cascade.
--
-- c_sharp is absent deliberately: it has no indents.scm, and the guard in the
-- FileType callback keeps it on Neovim's bundled GetCSIndent.
local TS_INDENT_SKIP = {
   html = true,
}

return {
   {
      "nvim-treesitter/nvim-treesitter",
      -- branch = "main" on purpose. 03-plugins.md pins "master" because it was
      -- written against Neovim 0.11, where main was not yet usable. main
      -- REQUIRES 0.12+, this machine runs 0.12.4, and master is feature-frozen
      -- and will stop receiving parsers. main is a full rewrite: the
      -- nvim-treesitter.configs module and its ensure_installed/highlight/indent
      -- tables no longer exist, which is why the setup below looks nothing like
      -- the doc's snippet.
      branch = "main",
      lazy = false,
      priority = 800,
      build = ":TSUpdate",
      config = function()
         local ts = require("nvim-treesitter")

         -- .xsd and .xaml are XML; without this they have no registered parser
         -- and treesitter refuses to start on them.
         pcall(vim.treesitter.language.register, "xml", { "xsd", "xaml" })

         -- Installs whatever is missing and skips the rest. Asynchronous, so a
         -- first launch on a new machine keeps working while parsers compile.
         pcall(ts.install, PARSERS)

         vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("rc_treesitter", { clear = true }),
            pattern = TS_FILETYPES,
            desc = "Start treesitter highlighting and indentation",
            callback = function(ev)
               -- pcall because a parser may still be compiling on first launch
               if not pcall(vim.treesitter.start) then return end
               if TS_INDENT_SKIP[ev.match] then return end

               -- Only hand indentation to treesitter when the language actually
               -- ships an indents.scm query. Without one, indentexpr returns 0
               -- for every line, and because indentexpr overrides both cindent
               -- and smartindent, the buffer loses auto-indent entirely and
               -- `gg=G` flattens it. c_sharp has no indent query, so this guard
               -- is what keeps C# working.
               local lang = vim.treesitter.language.get_lang(ev.match)
               if lang and vim.treesitter.query.get(lang, "indents") then
                  vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
               end
            end,
         })
      end,
   },

   { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

   -- Treesitter-aware bracket coloring, replacing luochen1990/rainbow. Also
   -- answers the "Rainbow Braces" Visual Studio extension.
   --
   -- submodules = false is REQUIRED here, not cosmetic. This repo declares a
   -- test/bin submodule hosted on gitlab.com, which this network answers with
   -- HTTP 403. The failed submodule fails the whole clone, so lazy never clears
   -- its .cloning marker and re-clones the plugin on EVERY startup. The
   -- submodules are test fixtures and LuaCATS type stubs with no runtime role.
   { "HiPhish/rainbow-delimiters.nvim", event = "VeryLazy", submodules = false },

   {
      "gbprod/yanky.nvim",
      opts = {},
      keys = {
         { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" } },
         { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" } },
         { "<C-p>", "<Plug>(YankyPreviousEntry)" },
      },
   },

   -- One formatter framework replacing vim-autoformat, json-formatter.vim and
   -- vim-pwsh-formatter. csharpier is added in doc 04.
   {
      "stevearc/conform.nvim",
      cmd = "ConformInfo",
      opts = {
         formatters_by_ft = {
            json = { "jq" },
            xml = { "xmllint" },
         },
      },
   },

   { "mbbill/undotree", keys = { { "<F9>", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" } } },

   -- Per-directory sessions, replacing xolox/vim-session. No lock files, no
   -- g:session_* settings.
   {
      "folke/persistence.nvim",
      event = "BufReadPre",
      opts = {},
      keys = {
         { "<leader>qs", function() require("persistence").load() end, desc = "Restore session for cwd" },
         { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      },
   },

   { "catgoose/nvim-colorizer.lua", event = "VeryLazy", opts = {} },

   -- Many more text objects: `ci,` between commas, `cia` a function argument,
   -- `ci'` from anywhere on the line, next/last variants (`cin)`). For C#
   -- method calls with long argument lists this is a daily workhorse;
   -- 03-plugins.md section 8 rates it the highest value-per-byte addition.
   { "wellle/targets.vim", event = "VeryLazy" },

   -- Paired bracket mappings: ]q/[q walk the quickfix list (build errors),
   -- ]b/[b buffers, ]e exchange lines, yon toggle numbers, yow toggle wrap.
   -- Turns the build-errors-to-quickfix workflow into two keystrokes.
   -- Note ]c/[c stay with gitsigns (hunk navigation), which is set per buffer.
   { "tpope/vim-unimpaired", event = "VeryLazy" },

   -- Carried over from _vimrc.plug, still worth their RAM.
   { "tpope/vim-surround" },
   { "tpope/vim-repeat" },
   { "godlygeek/tabular", cmd = "Tabularize" },
   { "tpope/vim-sleuth" },
   -- vim-matchup's treesitter integration used the old module system, which the
   -- main branch removed. It works fine standalone.
   { "andymass/vim-matchup", event = "VeryLazy" },
   { "sukima/xmledit", ft = { "xml", "xsd", "xaml", "html" } },
   { "tpope/vim-jdaddy", ft = "json" },
   { "chrisbra/csv.vim", ft = "csv" },
   { "chrisbra/unicode.vim", cmd = { "UnicodeName", "UnicodeTable", "Digraphs" } },
   { "wellle/visual-split.vim", cmd = { "VSSplit", "VSSplitAbove", "VSSplitBelow" } },
   { "dhruvasagar/vim-zoom" },
   -- no treesitter parser exists for VB, so this stays the .cls/.bas syntax
   { "tacahiroy/vim-vb", ft = "vb" },
   { "aklt/plantuml-syntax", ft = "plantuml" },
   { "reedes/vim-wordy", cmd = { "Wordy", "WordyWordy" } },
   { "aserebryakov/vim-todo-lists" },

   {
      "vimwiki/vimwiki",
      branch = "dev",
      init = function()
         vim.g.vimwiki_list = {
            { path = "~/vimwiki/", syntax = "markdown", ext = ".md" },
         }

         -- Without this, vimwiki claims EVERY .md file on the machine as
         -- filetype=vimwiki, not markdown. Measured, not theoretical: it breaks
         -- markdown treesitter highlighting, markdown-preview (ft="markdown"),
         -- conform, and the ltex grammar server, all of which key off the
         -- markdown filetype. Files under ~/vimwiki still get filetype=vimwiki.
         vim.g.vimwiki_global_ext = 0
      end,
   },

   {
      "mogelbrod/vim-jsonpath",
      ft = "json",
      init = function() vim.g.jsonpath_register = "*" end,
      config = function()
         vim.api.nvim_create_autocmd("FileType", {
            pattern = "json",
            callback = function()
               vim.keymap.set("n", "<leader>d", "<cmd>call jsonpath#echo()<cr>",
                  { buffer = true, silent = true, desc = "Echo JSON path" })
               vim.keymap.set("n", "<leader>g", "<cmd>call jsonpath#goto()<cr>",
                  { buffer = true, silent = true, desc = "Go to JSON path" })
            end,
         })
      end,
   },

   -- Grammar checking lives in plugins/lsp.lua now, as the ltex-ls-plus language
   -- server. dpelle/vim-LanguageTool (a "keep" in 03-plugins.md) was removed:
   -- it drives the LanguageTool CLI with `--api`, which LanguageTool 6.x no
   -- longer accepts.
   -- Renders markdown IN the buffer while it stays fully editable: styled
   -- headings, aligned tables, checkboxes, concealed link syntax, highlighted
   -- code blocks. Complements markdown-preview (browser) rather than replacing
   -- it; this is for writing, that is for reviewing the final output.
   {
      "MeanderingProgrammer/render-markdown.nvim",
      dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
      ft = { "markdown", "vimwiki" },
      opts = {
         -- vimwiki pages are filetype=vimwiki, not markdown, so they need
         -- listing explicitly or the wiki renders as plain text
         file_types = { "markdown", "vimwiki" },
      },
      config = function(_, opts)
         -- vimwiki overrides the markdown filetype, so the parser has to be
         -- registered against it or the plugin finds none for wiki pages.
         -- This does NOT hand vimwiki's highlighting to treesitter; that still
         -- comes from vimwiki's own syntax, which knows about wiki links.
         pcall(vim.treesitter.language.register, "markdown", "vimwiki")
         require("render-markdown").setup(opts)
      end,
   },

   {
      "iamcco/markdown-preview.nvim",
      build = "cd app && npm install",
      ft = "markdown",
      init = function()
         vim.g.mkdp_page_title = "「${name}」"
         vim.g.mkdp_filetypes = { "markdown" }
      end,
   },
}
