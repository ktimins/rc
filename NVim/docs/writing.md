# Writing

Markdown, grammar checking, and the wiki.

## Grammar and spelling

A language server checks grammar in markdown, plain text, git commit messages, LaTeX, reStructuredText and AsciiDoc. Findings appear as ordinary diagnostics, which means every diagnostic tool works on them.

| Key | Does |
|---|---|
| `]d` / `[d` | Next / previous finding |
| `<C-w>d` | Read the full explanation |
| `gra` | Code action: accept a suggestion, or add the word to the dictionary |
| `,lb` | Every finding in this buffer |

Findings are severity `hint` deliberately, so prose suggestions sit below real errors rather than shouting alongside them.

The messages are explanatory rather than terse. "The singular demonstrative pronoun 'this' does not agree with the plural verb 'are'" tells you what is wrong and why, which is more useful than a squiggle.

Writing a commit message in `nvim` gets this automatically, since `gitcommit` is one of the covered filetypes.

## Vim's own spell checking

Separate from grammar, and complementary.

| Key | Does |
|---|---|
| `,ss` | Toggle spell checking |
| `,sn` / `,sp` | Next / previous misspelling |
| `,sa` | Add the word under the cursor to the dictionary |
| `,s?` | Suggest corrections |
| `yos` | Toggle spell (unimpaired) |

## Prose style

| Command | Does |
|---|---|
| `:Wordy weak` | Highlight weak and hedging words |
| `:Wordy redundant` | Highlight redundancies |
| `:Wordy passive-voice` | Highlight passive constructions |
| `:Wordy business-jargon` | Highlight jargon |
| `:NoWordy` | Clear the highlighting |

Style opinions rather than errors. Useful for documentation you want read.

## Rendering markdown in the buffer

Markdown is rendered **in place** while staying fully editable: headings get styled and given icons, tables align themselves, checkboxes become symbols, link syntax is concealed down to the text, code blocks get a background and a language label, block quotes and callouts get a marker.

The line the cursor is on reverts to raw syntax so you can edit it, then re-renders when you move away. That is the whole trick: you see the formatted document while writing it, without a preview window and without losing access to the markup.

| Command | Does |
|---|---|
| `:RenderMarkdown toggle` | Turn rendering on or off |
| `:RenderMarkdown expand` | Reveal more raw syntax around the cursor |
| `:RenderMarkdown contract` | Reveal less |

This works in the wiki too. Wiki pages are filetype `vimwiki` rather than `markdown`, which the plugin does not pick up on its own, so both the filetype and a markdown parser registration are configured for it.

Rendering and the browser preview are complements, not alternatives: this one is for writing, the preview is for checking the final output.

## Markdown preview

| Command | Does |
|---|---|
| `:MarkdownPreview` | Open a live preview in the browser |
| `:MarkdownPreviewStop` | Stop it |
| `:MarkdownPreviewToggle` | Toggle |

The preview updates as you type and follows your scroll position.

## Working with markdown

| Key | Does |
|---|---|
| `,cw` | Toggle display wrapping, with `j`/`k` following screen lines |
| `,z` | Zen mode: centre the text, hide the chrome |
| `<F10>` | Outline of the headings |
| `gx` | Open the link under the cursor in a browser |

`,cw` then `,z` is the combination for actually writing rather than editing.

Tables can be aligned with `:Tabularize /|`.

Fenced code blocks get real syntax highlighting for the language they declare.

## Scratch buffers

| Key | Does |
|---|---|
| `,q` | Open `~/buffer` |
| `,x` | Open `~/buffer.md` |

Two always-there files for thinking out loud, carried over from the gVim config. `,x` gets markdown treatment including grammar checking.

## The wiki

| Key | Does |
|---|---|
| `,ww` | Open the wiki index |
| `,wt` | Open the index in a new tab |
| `,ws` | Select which wiki |
| `,wi` | Diary index |
| `,w,w` | Today's diary page |
| `,w,t` | Tomorrow's |
| `,w,y` | Yesterday's |
| `,w,i` | Regenerate the diary links |

Inside a wiki page:

| Key | Does |
|---|---|
| `<CR>` | Follow the link under the cursor, creating the page if needed |
| `<Backspace>` | Go back |
| `<Tab>` / `<S-Tab>` | Next / previous link |
| `+` | Turn the word or selection into a link |
| `<C-Space>` | Toggle a checkbox |

The wiki lives at `~/vimwiki` and uses markdown.

Files there are filetype `vimwiki`, not `markdown`, which is how the plugin's link handling and diary features activate. Markdown files **outside** the wiki stay plain markdown and get treesitter highlighting, preview and grammar checking. That separation is deliberate and had to be configured: by default the wiki plugin claims every `.md` file on the machine, which silently breaks all three of those things everywhere else.

## Checklists

`.todo` files get checkbox management: toggle items done, reorder them, and keep parent items in sync with their children.
