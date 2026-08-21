-- Language server infrastructure.
--
-- Mason installs the server binaries. The C# stack (roslyn, netcoredbg,
-- csharpier) and its extra registry arrive with doc 04; this file currently
-- carries Mason itself plus the grammar checker.

return {
   {
      "mason-org/mason.nvim",
      lazy = false,
      priority = 850, -- before anything that expects a server binary on PATH
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

         -- ltex-ls-plus: grammar and spell checking through LanguageTool.
         --
         -- Replaces dpelle/vim-LanguageTool, which 03-plugins.md kept but which
         -- cannot work against a current LanguageTool: it drives the CLI with
         -- `--api`, removed in LanguageTool 6.x. Doc 03 names this server as the
         -- upgrade path. Findings surface as ordinary diagnostics, so they work
         -- with :Telescope diagnostics and the quickfix list like anything else.
         --
         -- ltex-ls-plus is the maintained fork; the original valentjn/ltex-ls is
         -- abandoned. The Mason package bundles its own JDK 21, so this does NOT
         -- depend on a system Java being installed or on PATH.
         --
         -- Configured through Neovim's native vim.lsp.config (0.11+), so
         -- nvim-lspconfig is not required. This must run after mason.setup(),
         -- which is what puts the Mason bin directory on PATH.
         vim.lsp.config("ltex_plus", {
            cmd = { "ltex-ls-plus" },
            filetypes = { "markdown", "text", "gitcommit", "tex", "rst", "asciidoc" },
            -- fall back to the file's own directory outside a repo, so scratch
            -- notes still get checked
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
      end,
   },
}
