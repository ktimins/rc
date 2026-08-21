# Colemak

The single most important thing to understand about this configuration. Everything else is built on top of it.

## The contract

Your Planck sits on its **QWERTY layer** while Neovim is focused. The OS therefore sends plain QWERTY characters, and Neovim translates them to Colemak only where it knows it is reading **text** rather than **commands**.

| Where | What happens |
|---|---|
| Normal, Visual, Operator-pending | Raw QWERTY. `j` is down, `dd` deletes a line, exactly as your muscle memory expects |
| Insert and Replace | Translated to Colemak |
| Command line after `:` | Translated |
| Search after `/` or `?` | Translated |
| The character argument of `f` `F` `t` `T` `r` | Translated |
| Register names, marks, macro names | Raw QWERTY, never translated |
| Terminal mode | NOT translated. Flip the hardware layer, as with any other app |

## What changed from gVim

The `f`/`F`/`t`/`T`/`r` row is the improvement. In gVim those take a raw character, so you had to flip the Planck to Colemak, press the key, and flip back. Here they are translated, so **the layer flip is no longer needed for them**.

That is the only behavioral difference. Everything else matches gVim.

## Why this works

gVim uses a block of `noremap!` mappings, which paint Insert and Command-line mode. That is an approximation: some text moments live inside Normal mode, and the argument to `f` or `r` refers to a letter in your text, which is content, not grammar.

This config uses `:lmap` language mappings instead, which is the feature Vim built for exactly this situation. You declare once that your text language is Colemak and your command language is QWERTY, and every place the editor knows it is reading text follows from that. It is also the only mechanism that can reach the `f`/`t`/`r` arguments at all.

## The translation table

Only 17 keys differ. The other letters (`a b c h m q v w x z`) are in the same place on both layouts.

```
QWERTY row   Colemak result
qwertyuiop -> qwfpgjluy;
asdfghjkl; -> arstdhneio
zxcvbnm    -> zxcvbkm
```

So in Insert mode, pressing the key labelled `k` produces `e`, and the key labelled `;` produces `o`.

## Turning it off temporarily

`CTRL-^` in Insert mode toggles translation for the **current buffer**. Press it again to turn it back on.

Use this when you need to type raw QWERTY: a password, a file path that fights the translation, or pasting-by-typing.

The statusline shows which mode you are in:

| Indicator | Meaning |
|---|---|
| `CMK` | Translating. Normal state |
| `QWE` | Raw QWERTY. You toggled it off in this buffer |

Buffers you open afterwards always start translated, even if you left another buffer toggled off. That is deliberate: Vim's built-in toggle moves a global value as a side effect, so this config repairs it when you leave Insert mode. Without that repair, one forgotten toggle would silently disable translation in every file you opened for the rest of the session.

## When typing comes out wrong

**Everything is raw QWERTY in one file but fine in others.** You pressed `CTRL-^` in that buffer. Check the statusline for `QWE`, press `CTRL-^` in Insert mode to restore.

**Everything is raw QWERTY everywhere, in every new file too.** The lmaps are not loaded. Check `:lmap` lists 34 entries.

**The command line is not translating but Insert mode is.** The `:` mapping did not take. Command lines start with language mappings disabled by design, and this config remaps `:` to enable them on entry. Check `:verbose nmap :` shows only this config.

**`f` and `r` take the wrong character.** `iminsert` is not 1 in that buffer. Check `:set iminsert?`.

**A plugin's prompt takes raw QWERTY.** Plugins that read a key with their own `getchar()` bypass language mappings entirely. Jump-label motions like flash.nvim are the notable case, which is why they are not installed. The labels appear on screen so it is workable, but know it before adopting one.

**The embedded terminal takes raw QWERTY.** Expected. Terminal mode is not translated; flip the hardware layer.

## Verifying it

There is an automated acceptance suite:

```sh
nvim --headless -c "luafile $LOCALAPPDATA/nvim/tests/colemak_spec.lua" +qa!
```

22 checks covering all three rows, shifted keys, Normal mode staying raw, the `f`/`r` arguments, macro round-trips and the toggle. **Re-run it after adding any plugin.** A plugin that claims `:` or one of the 17 translated letters breaks the contract silently, with no error message.
