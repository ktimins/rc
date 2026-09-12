# 01: Colemak Handling in Neovim (Language Mappings)

This is the make-or-break piece of the migration. Implement it first, alone, in a minimal config, and run the acceptance checklist at the bottom before building anything else on top.

## 1. Background: what the current Vim setup does and why

The user's daily typing layout is Colemak. Their Planck keyboard has two hardware layers: Colemak (daily driver) and QWERTY. While in Vim, the QWERTY layer is active, so the OS (and therefore Vim) receives plain QWERTY characters for whatever physical key is pressed. This makes Normal/Visual/Operator-pending commands work with the user's original QWERTY Vim muscle memory, with no software involvement.

The problem that leaves: typed text (insert mode, and text after `:` or `/`) would come out as QWERTY, but the user's muscle memory for typing words is Colemak. The current `_vimrc` fixes this with a block of `noremap!` mappings (the "Colemak" fold at the bottom of `_vimrc`). `noremap!` maps a key in Insert mode AND Command-line mode simultaneously. Each mapping rewrites the received QWERTY character into the character that Colemak would produce at the same physical key position.

Direction of translation, stated precisely: **lhs = the character the OS sends (QWERTY label of the physical key), rhs = the character Colemak has at that same physical position.** Example: `noremap! e f` because the physical key labeled `e` on QWERTY holds `f` on Colemak. When the user "thinks Colemak" and reaches for the letter f, their finger goes to that physical key, Vim receives `e`, the mapping emits `f`. Correct result.

Only 16 of the 26 letters differ between QWERTY and Colemak; the other 10 (`a b c h m q v w x z`) are identical and need no mapping. The `;`/`:` key also differs (it holds `o`/`O` on Colemak), for 17 differing keys in total. The current block covers all 17 in both cases, including the shifted pairs `P → :` (QWERTY Shift+p position holds `:` on Colemak) and `: → O`. The block is complete and correct; the table in section 3 below is the same data and must not be "fixed" or extended.

One gap existed in the old setup: the single-character arguments of `f` `F` `t` `T` `r` (Normal-mode commands that take a literal text character) are not affected by Insert/Command-line mappings, so they arrived untranslated. The user worked around this by quickly flipping the Planck to the Colemak layer, pressing the character, and flipping back. The design below closes that gap in software, so the layer-flip is no longer needed for those commands. The user has approved this behavior change.

## 2. Chosen design: `:lmap` language mappings ("Option C")

Vim/Neovim has a purpose-built mechanism for exactly this situation: language mappings. Per Neovim's documentation (`:h language-mapping` in map.txt), `:lmap` defines mappings that apply to:

- Insert mode
- Command-line mode
- entering a search pattern
- the argument of commands that accept a text character (`f`, `F`, `t`, `T`, `r`), documented as "Lang-Arg"
- the `input()` line

### Why this mechanism, in plain English

Every keystroke in Vim is one of two things: part of a command (grammar) or a character of text (content). The old `noremap!` hack worked by enumerating the two modes where content usually happens (Insert and the command line) and painting them with maps. That was a good approximation, but an approximation: some content moments live inside Normal mode (the character given to `f` or `r` refers to a letter in the text, which is content, not grammar), and the approximation had no off switch and no awareness of where characters come from.

Language mappings are Vim's first-class concept for exactly this distinction. The feature was built for people whose typed language differs from their command language (originally Russian, Greek, and Hebrew typists running Vim commands on US keyboards), which is structurally identical to "types Colemak, commands QWERTY". Choosing lmap means telling the editor once "my text language is Colemak, my command language is QWERTY", and every place the editor knows it is reading text follows from that single declaration: insert, search, command-line text, `f`/`t`/`r` targets, prompts. The practical wins: the `f`/`t`/`r` hardware layer-flip dance disappears; one switch (`iminsert`, toggled by `CTRL-^`) turns the whole scheme on and off per buffer; recorded macros contain real readable text; and plugin-generated keystrokes can never be corrupted by the translation, because lmaps only ever touch typed characters. The one cost is a documented quirk on the `:` command line (covered below), neutralized by a single extra mapping.

In the evolution framing from the design discussion: `noremap!` was a trait that was good enough to survive; lmap is the same trait selected on purpose, and it is the only mechanism in the editor that can reach the `f`/`t`/`r` arguments at all, so no amount of `map!`-style tinkering could ever close that gap.

### The mechanics

That is precisely the set "characters that are text, not command grammar". Whether the lmaps are active is governed by two buffer-local options:

- `iminsert` = 1 → lmaps active in Insert mode and for the `f`/`t`/`r` arguments. Toggleable per buffer with `CTRL-^` in Insert mode; the state is remembered.

> **Correction (implemented 2026-08-21).** `CTRL-^` is NOT purely per-buffer. Measured across three distinct buffers on Neovim 0.12.4: `i_CTRL-^` moves the GLOBAL `iminsert` as well as the buffer-local one. Because new buffers inherit the global default, toggling translation off in one buffer silently disables it in every buffer opened afterwards, and the symptom ("Colemak stopped working") is far removed from the cause. The option itself is genuinely buffer-local when set directly (two buffers held different values), so this is specifically about what `CTRL-^` does.
>
> The implemented fix repairs the global rather than replacing the toggle: an `InsertLeave` autocmd resets the global `iminsert` to 1, leaving the buffer-local value alone. Setting global scope explicitly does not disturb the buffer-local value. `OptionSet` does NOT fire for `i_CTRL-^` (verified), which is why `InsertLeave` is the repair point.
>
> Remapping `CTRL-^` to a Lua callback was tried and rejected: the built-in toggles synchronously within the input stream and a callback does not, risking translation of the first characters typed after the toggle.
- `imsearch` = -1 → search patterns (`/`, `?`) follow whatever `iminsert` says. (A value of 1 would make search state independent; we use -1 so one switch controls everything.)

### The one documented catch, and its fix

Per the docs (map.txt language-mapping, and `:h c_CTRL-^`): **on a normal `:` command line, language mappings start disabled and must be enabled with `CTRL-^`; this state is NOT remembered between command lines.** Left alone, that would break the current behavior where everything typed after `:` (command names, `:%s/pat/rep/` text, filenames) is Colemak-translated.

The fix is the standard trick used by `'keymap'` users of other languages: remap `:` itself to `:<C-^>`, so every command line begins with language mappings switched on. Because the `:` cmdline always starts in the disabled state, `<C-^>` deterministically enables (never accidentally disables). The mapping is non-recursive and applies in Normal and Visual mode (Visual `:` still gets the automatic `'<,'>` range, and counts like `5:` still produce their range, because the mapping just plays the literal keys).

Two properties of lmaps that are improvements over the old `noremap!` approach, both documented:

- lmaps only apply to **typed** characters, never to characters produced by other mappings. Plugin mappings that feed `:SomeCommand<CR>` sequences can never be corrupted by the translation. (The old `cmap` approach could, in the rare case of a plugin using recursive mappings.)
- lmaps are applied **while recording** a macro and NOT re-applied on playback. Recorded registers therefore contain the real (Colemak) text and replay deterministically. The old approach recorded raw QWERTY and re-translated on every replay; net behavior is the same, but registers are now human-readable.

### Rejected alternatives (do not implement these)

- **`langmap` option**: solves the mirror-image problem (OS sends Colemak, translate Normal-mode commands back to QWERTY). Wrong direction for this setup; the Planck's hardware layer switch already handles Normal mode.
- **Porting the `noremap!` block as-is**: works (it is the old behavior exactly) but keeps the `f`/`t`/`r` layer-flip annoyance and gains none of the lmap benefits. Kept as fallback variants A and D in section 6 only.
- **`inoremap <Esc> <Esc>:set iminsert=0<CR>`**: many online `'keymap'` examples include this reset-on-escape idiom. It must NOT be used here. It would turn translation off for the `f`/`t`/`r` arguments and for search, which is the opposite of what we want. `iminsert` must stay 1 permanently (the user toggles with `CTRL-^` manually in the rare case they want raw QWERTY typing).
- **Keeping the old `noremap!` block AND the lmaps simultaneously**: forbidden. Two translation layers on the same keys risks double translation. The old block must not exist in the Neovim config at all.

## 3. Implementation

Create `lua/colemak.lua` in the Neovim config directory and call `require("colemak").setup()` as the FIRST line of `init.lua` (before plugin managers, so the mappings exist even if plugin setup fails).

```lua
-- lua/colemak.lua
-- QWERTY-received -> Colemak-emitted translation for typed text.
-- Normal/Visual/Operator-pending stay raw QWERTY (hardware layer handles them).
-- Full design and acceptance tests: nvim-migration/01-colemak.md in the rc repo.

local M = {}

-- lhs = character the OS sends (QWERTY label of the physical key)
-- rhs = character Colemak has at that same physical position
M.table = {
  e = "f", r = "p", t = "g", y = "j", u = "l", i = "u", o = "y", p = ";",
  s = "r", d = "s", f = "t", g = "d", j = "n", k = "e", l = "i", [";"] = "o",
  n = "k",
  E = "F", R = "P", T = "G", Y = "J", U = "L", I = "U", O = "Y", P = ":",
  S = "R", D = "S", F = "T", G = "D", J = "N", K = "E", L = "I", [":"] = "O",
  N = "K",
}

function M.setup()
  -- Language mappings: Insert, Cmdline, search, f/F/t/T/r arguments, input().
  -- vim.keymap.set is non-recursive by default (:lnoremap semantics).
  for lhs, rhs in pairs(M.table) do
    vim.keymap.set("l", lhs, rhs)
  end

  -- Activate the lmaps. Both options are buffer-local; setting via vim.o at
  -- startup sets the global default that every new buffer inherits.
  vim.o.iminsert = 1   -- Insert mode + f/F/t/T/r arguments
  vim.o.imsearch = -1  -- search patterns follow iminsert

  -- lmaps start DISABLED on each ':' command line (documented behavior) and
  -- CTRL-^ enables them for that command line. Auto-enable on entry:
  vim.keymap.set("n", ":", ":<C-^>", { desc = "Cmdline with Colemak lmaps on" })
  vim.keymap.set("x", ":", ":<C-^>", { desc = "Cmdline with Colemak lmaps on" })
end

return M
```

Notes for the implementer:

- Mode `"l"` in `vim.keymap.set` is the `:lmap` map-command prefix (the API accepts map command prefixes as mode short-names). If a given Neovim build ever rejects it, the equivalent fallback is `vim.cmd(("lnoremap %s %s"):format(lhs, rhs))` inside the same loop, with `lhs` values `;` and `:` passed as-is (they need no escaping in this position).
- Do not add `silent = true` to the `:` mappings; the command line must echo normally.
- Do not make the lmaps buffer-local; they are global on purpose. Per-buffer control comes from `iminsert` toggling, not from the mappings.
- Before going further, check no plugin claims these keys: `:verbose lmap e` should show only this config, and `:verbose nmap :` should show only this config.

### Optional: status indicator

`iminsert` is toggleable per buffer with `CTRL-^` in Insert mode, so it is useful to see the state. With lualine (doc 03), add a tiny component:

```lua
-- returns CMK when translation is on, QWE when toggled off
local function layer() return vim.bo.iminsert == 1 and "CMK" or "QWE" end
-- then in lualine sections: lualine_x = { layer, "encoding", "filetype" }
```

## 4. Behavior comparison: old `noremap!` vs new lmap design

| Context | Old Vim behavior | New Neovim behavior |
|---|---|---|
| Insert / Replace mode | translated | translated (identical) |
| Search `/` `?` | translated | translated (via `imsearch = -1`) |
| `:` command line | translated | translated (via the `:` → `:<C-^>` mapping) |
| `f` `F` `t` `T` `r` arguments | NOT translated (user flipped hardware layer) | translated ✓ layer-flip no longer needed |
| Normal / Visual / O-pending commands | raw QWERTY | raw QWERTY (identical) |
| Registers, marks, macro register names (`"a`, `m{c}`, `q{c}`, `<C-r>{c}`) | raw QWERTY | raw QWERTY (lmaps do not apply to these; identical) |
| Macro record/replay of insert-mode text | records raw QWERTY, re-translates on replay | records translated text, replays literally; same net result, readable registers |
| Pasting into cmdline via `<C-r>+` | pasted text untouched | pasted text untouched (lmaps only affect typed characters) |
| Text fed by plugin mappings | untouched with noremap plugins | untouched always (lmaps never apply to mapped characters) |
| Temporary raw-QWERTY typing | not possible without editing vimrc | `CTRL-^` in Insert mode toggles per buffer |
| `input()` prompts | translated | starts untranslated; press `CTRL-^` inside the prompt, or see note below |
| Neovim `:terminal` | n/a (gvim had no terminal) | NOT translated; flip the hardware layer as with any non-Vim app |

The `input()` row is the only regression, and it is small: the config's own prompts (`ChangeTabStops`, `FindAll`) mostly take numbers, which are unmapped anyway. Doc 02 ports those functions to `vim.ui.input`, and with a UI plugin that renders `vim.ui.input` as a real insert-mode buffer (e.g. `snacks.nvim` input or `dressing.nvim`), the prompt becomes ordinary Insert mode where the lmaps apply automatically. If no such plugin is installed, `CTRL-^` inside the prompt enables translation for that prompt.

## 5. Acceptance checklist

Run every one of these in a fresh `nvim` with only `colemak.lua` loaded. "Type X" means press the keys that produce X on a plain QWERTY keyboard (any normal keyboard, or the Planck's QWERTY layer).

1. `:lmap` (type it as `;` `u` `m` `a` `r` since the cmdline translates: the physical keys that SEND those letters... simpler: run `nvim` then paste the command with `<C-r>+`, or check from a terminal: `nvim --headless "+lmap" +q`). Expect 34 mappings listed.
2. Insert mode: type the QWERTY top row `qwertyuiop` → buffer shows `qwfpgjluy;` (the Colemak top row). Type home row `asdfghjkl;` → `arstdhneio`. Type bottom row `zxcvbnm` → `zxcvbkm`.
3. Uppercase: type `QWERTYUIOP` → `QWFPGJLUY:`.
4. Escape to Normal mode, press `j` → cursor moves DOWN (not remapped to n), press `k` → up, `dd` deletes a line, `ciw` changes a word. All raw QWERTY.
5. Search: press `/` then type `qwert` → the search prompt shows `qwfpg`.
6. Command line: press `:` then type `qwert` → cmdline shows `qwfpg`. Then `<Esc>`. Also verify a real command: `:e` is typed as `:` then the key that sends `k` (because `k` translates to `e`), and completes as `:e`.
7. Visual mode: select a line with `V`, press `:` → cmdline shows `'<,'>` with translation active (type `qwert` after it to confirm → `qwfpg`).
8. Lang-Arg: put `abc def` on a line, cursor at start, press `f` then the key that sends `k` → cursor lands on the `e` of `def` (because `k` translated to `e`). Press `r` then the key that sends `k` → character becomes `e`.
9. Persistence: leave and re-enter Insert mode several times, open a second file (`:edit` another path); translation still active everywhere (`iminsert` global default carried to the new buffer).
10. Macro round-trip: `qa` `i` type `qwert` `<Esc>` `q`, move to an empty line, `@a` → line reads `qwfpg` (no double translation, no loss).
11. Toggle: in Insert mode press `CTRL-^`, type `qwert` → literal `qwert` appears; press `CTRL-^` again, type `qwert` → `qwfpg`.
12. Counts: press `5` then `:` → cmdline shows `:.,.+4` with translation active.
13. No bleed into command grammar: in Normal mode press `"` then `a` then `y` `y` (yank line into register a) → works; `q` `a` ... `q` records into register a, not a translated register.

If test 6 or 7 fails (cmdline untranslated), the `:` mapping did not take effect; check `:verbose nmap :` for a plugin conflict. If test 8 fails, `iminsert` is not 1 in that buffer (`:set iminsert?`); look for a plugin or autocmd resetting it. If ALL translation tests fail, mode `"l"` was rejected; use the `vim.cmd` fallback from section 3.

## 6. Variant matrix: every option at implementation depth

There are two independent decisions here, and keeping them separate is what makes the choices understandable. The **mechanism** (lmap vs `noremap!`) decides the behavior. The **language** (Lua vs Vimscript) only decides where the code lives; Neovim's mapping engine is identical either way.

| | Lua | Vimscript |
|---|---|---|
| **lmap** (chosen behavior: translates insert, cmdline, search, AND `f`/`t`/`r` args; toggleable) | **Variant C**: section 3, the main implementation | **Variant B**: shared `colemak.vim`, below |
| **`noremap!`** (legacy behavior: insert + cmdline only; `f`/`t`/`r` need the hardware layer-flip) | **Variant A**: below | **Variant D**: the existing `_vimrc` block, verbatim |

How to choose:

- Mechanism: lmap (B or C) unless a real blocker appears in testing; A/D are bit-for-bit the old behavior and exist as escape hatches.
- Language: match your config track. Lua config (docs 02/03) → variant C. Vimscript config (doc 06) → variant B.
- Variant B has a property no other cell has: the SAME file can be sourced by gVim (Vim 9) and Neovim, because lmap/`iminsert` are original Vim features, not Neovim additions. Adopting it in `_vimrc` too (replacing the old `noremap!` block there) puts both editors in behavioral lockstep AND gives gVim the `f`/`t`/`r` upgrade. This is optional: if gVim should stay exactly as it has been for years, leave `_vimrc` alone and use B/C only on the Neovim side, accepting that the two editors then differ on `f`/`t`/`r`.
- VsVim stays on variant D forever: `_vsvimrc` already contains it, and VsVim does not implement lmap/`iminsert`, so B/C are impossible there.
- Never enable two variants at once in the same editor (double translation).
- The acceptance checklist (section 5) applies to every variant, with these adjustments for the `noremap!` variants A and D: test 8 (`f`/`r` arguments) is EXPECTED to fail, that gap being the legacy behavior; test 11 (`CTRL-^` toggle) does not apply; and the `input()` note in section 4 does not apply (`input()` is covered by cmap in A/D).

### Variant A: `noremap!` in Lua

The translation table applied with mode `"!"` (`:noremap!`, Insert + Cmdline). No `iminsert`/`imsearch`, no `:` mapping.

```lua
for lhs, rhs in pairs(require("colemak").table) do
  vim.keymap.set("!", lhs, rhs)
end
```

### Variant B: lmap in Vimscript (shareable with gVim)

Save as `Vim/shared/colemak.vim` in the rc repo. From an `init.vim` or `_vimrc`: `source <path>/Vim/shared/colemak.vim`. From an `init.lua`: `vim.cmd.source(Machine.rc_repo .. "/Vim/shared/colemak.vim")`. Explicit lines rather than a loop, to match the existing vimrc style and stay greppable.

```vim
" colemak.vim - shared between gVim (Vim 9) and Neovim. NOT for VsVim.
" lhs = character the OS sends (QWERTY key label), rhs = the Colemak
" character at that same physical position.
" Design and acceptance tests: nvim-migration/01-colemak.md

lnoremap e f
lnoremap r p
lnoremap t g
lnoremap y j
lnoremap u l
lnoremap i u
lnoremap o y
lnoremap p ;
lnoremap s r
lnoremap d s
lnoremap f t
lnoremap g d
lnoremap j n
lnoremap k e
lnoremap l i
lnoremap ; o
lnoremap n k
lnoremap E F
lnoremap R P
lnoremap T G
lnoremap Y J
lnoremap U L
lnoremap I U
lnoremap O Y
lnoremap P :
lnoremap S R
lnoremap D S
lnoremap F T
lnoremap G D
lnoremap J N
lnoremap K E
lnoremap L I
lnoremap : O
lnoremap N K

" Activate. Both options are buffer-local; setting them here sets the
" global default that every new buffer inherits. Do NOT add any autocmd
" that resets iminsert on leaving Insert mode (see the rejected list).
set iminsert=1
set imsearch=-1

" ':' command lines start with lmaps disabled (documented behavior);
" auto-enable on entry. Counts and visual ranges are unaffected.
nnoremap : :<C-^>
xnoremap : :<C-^>
```

If this file is adopted in `_vimrc`, the old Colemak `noremap!` fold there must be deleted in the same change.

### Variant D: `noremap!` in Vimscript

The existing block, `_vimrc` lines 1455 through 1495, unchanged. This is the zero-change fallback, and permanently the right answer for `_vsvimrc`. Nothing to implement; it is already running in gVim and VsVim today.
