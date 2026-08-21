-- Language server infrastructure, diagnostics UI, and the non-C# servers.
-- The C# stack lives in plugins/csharp.lua.

return {
   {
      "mason-org/mason.nvim",
      lazy = false,
      priority = 850, -- before anything that expects a server binary on PATH
      dependencies = { "b0o/SchemaStore.nvim" },
      opts = {
         -- The community registry carries `roslyn`, built from the same source
         -- as the VS Code C# extension. roslyn.nvim's own README recommends it
         -- over the official registry's `roslyn-language-server`, which comes
         -- from nuget.org and lags behind. Both registries stay listed so every
         -- other package still resolves normally.
         registries = {
            "github:mason-org/mason-registry",
            "github:Crashdummyy/mason-registry",
         },
      },
      config = function(_, opts)
         require("mason").setup(opts)

         -- Everything below must run AFTER mason.setup(), which is what puts
         -- the Mason bin directory on PATH. Configured through Neovim's native
         -- vim.lsp.config (0.11+), so nvim-lspconfig is not required.

         -- ltex-ls-plus: grammar and spell checking through LanguageTool.
         --
         -- Replaces dpelle/vim-LanguageTool, which 03-plugins.md kept but which
         -- cannot work against a current LanguageTool: it drives the CLI with
         -- `--api`, removed in LanguageTool 6.x. Findings surface as ordinary
         -- diagnostics, so they work with :Telescope diagnostics and trouble.
         --
         -- ltex-ls-plus is the maintained fork; valentjn/ltex-ls is abandoned.
         -- The Mason package bundles its own JDK 21, so this does NOT depend on
         -- a system Java being installed or on PATH.
         vim.lsp.config("ltex_plus", {
            cmd = { "ltex-ls-plus" },
            filetypes = { "markdown", "text", "gitcommit", "tex", "rst", "asciidoc" },
            root_markers = { ".git" },
            settings = {
               ltex = {
                  language = "en-US",
                  -- the language ids Neovim sends are filetypes, which do not
                  -- all match ltex's defaults (it expects "latex", not "tex")
                  enabled = {
                     "markdown", "text", "gitcommit", "tex", "rst", "asciidoc",
                     "latex", "restructuredtext", "html", "org",
                  },
                  additionalRules = { enablePickyRules = false },
                  diagnosticSeverity = "hint",
               },
            },
         })
         vim.lsp.enable("ltex_plus")

         -- lemminx: XSD-aware XML. Validates against referenced schemas,
         -- completes tags and attributes FROM the xsd, and hovers documentation
         -- out of it. 03-plugins.md section 8 calls this the highest-value
         -- filetype addition given the .xsd and Billing-XML work in _vimrc.
         vim.lsp.config("lemminx", {
            cmd = { "lemminx" },
            filetypes = { "xml", "xsd", "xsl", "xslt", "svg", "xaml" },
            root_markers = { ".git" },
         })
         vim.lsp.enable("lemminx")

         -- Schema-aware JSON: completion and validation for appsettings.json,
         -- launchSettings.json, global.json and a thousand other known file
         -- names, from schemastore.org. Very .NET-relevant.
         vim.lsp.config("jsonls", {
            cmd = { "vscode-json-language-server", "--stdio" },
            filetypes = { "json", "jsonc" },
            root_markers = { ".git" },
            settings = {
               json = {
                  schemas = require("schemastore").json.schemas(),
                  validate = { enable = true },
               },
            },
         })
         vim.lsp.enable("jsonls")
      end,
   },

   -- LSP progress in the corner. Roslyn takes noticeable time to load a large
   -- solution and says nothing meanwhile, so without this the editor simply
   -- feels dead until it finishes.
   { "j-hui/fidget.nvim", event = "LspAttach", opts = {} },

   -- A structured panel for diagnostics, references and quickfix: the closest
   -- thing to Visual Studio's Error List, which nothing in doc 04 replicates.
   --
   -- <leader>l for "lists". NOT <leader>x (the conventional trouble prefix):
   -- that is already the ~/buffer.md scribble mapping ported from _vimrc.
   {
      "folke/trouble.nvim",
      cmd = "Trouble",
      opts = {},
      keys = {
         { "<leader>ld", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (project)" },
         { "<leader>lb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
         { "<leader>ls", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
         { "<leader>lr", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "References / definitions" },
         { "<leader>lq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
         { "<leader>ll", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
      },
   },
}
