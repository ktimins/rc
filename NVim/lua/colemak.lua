-- Colemak handling: QWERTY-received -> Colemak-emitted translation for typed text.
--
-- The Planck keyboard sits on its QWERTY layer while Neovim is focused, so the
-- OS sends plain QWERTY characters. That is deliberate: Normal, Visual and
-- Operator-pending commands then match 25 years of QWERTY muscle memory with no
-- software involved. What needs fixing is TEXT, which the fingers type in
-- Colemak. These language mappings translate exactly the places where the
-- editor knows it is reading text and nowhere else.
--
-- Mechanism is :lmap (see :h language-mapping), not the noremap! block the old
-- _vimrc uses. lmap is the feature Vim built for this exact situation, and it is
-- the only one that reaches the character arguments of f/F/t/T/r, which the old
-- setup could not translate at all.
--
-- Full design, rejected alternatives, and the 13-item acceptance checklist:
-- Vim/vimrc/nvim-migration/01-colemak.md in this repo.

local M = {}

-- lhs = the character the OS sends (the QWERTY label of the physical key)
-- rhs = the character Colemak has at that same physical position
--
-- Only 17 keys differ between the two layouts. The other letters (a b c h m q v
-- w x z) sit in the same place on both and need no mapping. This table is
-- complete and verified against the layouts; do not extend it.
M.table = {
   -- top row: qwertyuiop -> qwfpgjluy;
   e = "f", r = "p", t = "g", y = "j", u = "l", i = "u", o = "y", p = ";",
   -- home row: asdfghjkl; -> arstdhneio
   s = "r", d = "s", f = "t", g = "d", j = "n", k = "e", l = "i", [";"] = "o",
   -- bottom row: zxcvbnm -> zxcvbkm
   n = "k",

   -- the same 17 keys shifted
   E = "F", R = "P", T = "G", Y = "J", U = "L", I = "U", O = "Y", P = ":",
   S = "R", D = "S", F = "T", G = "D", J = "N", K = "E", L = "I", [":"] = "O",
   N = "K",
}

function M.setup()
   -- Language mappings apply to Insert mode, the command line, search patterns,
   -- the f/F/t/T/r arguments, and input() prompts. vim.keymap.set is
   -- non-recursive by default, so this is :lnoremap semantics.
   for lhs, rhs in pairs(M.table) do
      vim.keymap.set("l", lhs, rhs)
   end

   -- Activate. Both options are buffer-local; setting them through vim.o at
   -- startup establishes the global default that every new buffer inherits.
   --
   -- iminsert must stay at 1 permanently. Do NOT add the common
   -- `inoremap <Esc> <Esc>:set iminsert=0<CR>` idiom seen in 'keymap' examples:
   -- it would kill translation for search and for the f/t/r arguments, which is
   -- the opposite of what this config wants. CTRL-^ in Insert mode is the
   -- intended per-buffer escape hatch.
   vim.o.iminsert = 1   -- Insert mode, and the f/F/t/T/r character arguments
   vim.o.imsearch = -1  -- search patterns follow iminsert rather than tracking separately

   -- i_CTRL-^ toggles translation, and measured behavior is that it moves the
   -- GLOBAL iminsert as well as the buffer-local one. Consequence: switching
   -- translation off in one buffer silently disables it in every buffer opened
   -- afterwards, and the symptom ("Colemak stopped working") is far removed from
   -- the cause.
   --
   -- The fix repairs the global rather than replacing the toggle. Remapping
   -- CTRL-^ to a Lua callback was tried and rejected: the built-in toggles
   -- synchronously within the input stream, a callback does not, so a
   -- replacement risks translating the first characters typed after the toggle.
   -- Vim's own code path stays in charge of the toggle; only the leak is fixed.
   --
   -- InsertLeave is the repair point because OptionSet does not fire for
   -- i_CTRL-^ (verified). Setting global scope explicitly leaves the
   -- buffer-local value intact, so the buffer you toggled stays toggled while
   -- every buffer opened later still starts translated.
   vim.api.nvim_create_autocmd("InsertLeave", {
      group = vim.api.nvim_create_augroup("colemak_iminsert_global", { clear = true }),
      desc = "Keep the global iminsert default at 1 so new buffers stay translated",
      callback = function()
         if vim.api.nvim_get_option_value("iminsert", { scope = "global" }) ~= 1 then
            vim.api.nvim_set_option_value("iminsert", 1, { scope = "global" })
         end
      end,
   })

   -- Documented quirk: on a ':' command line, language mappings start DISABLED
   -- and the state is not remembered between command lines. CTRL-^ toggles them
   -- for the current command line, so entering with it appended deterministically
   -- turns them ON (never accidentally off, since the start state is always
   -- disabled). Counts and the visual '<,'> range are unaffected, because the
   -- mapping just replays the literal keys.
   vim.keymap.set("n", ":", ":<C-^>", { desc = "Cmdline with Colemak lmaps on" })
   vim.keymap.set("x", ":", ":<C-^>", { desc = "Cmdline with Colemak lmaps on" })
end

return M
