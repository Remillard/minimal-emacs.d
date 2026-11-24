# VHDL in-editor compilation and language server

**Status:** Parked / not urgent. Current workflow (vhdl-mode projects, or manual
compile) is adequate. Revisit if bouncing between projects makes per-file
compile friction worth solving. A language server (see
[Language server](#language-server-vhdl_ls) below) is the other half of the
plan and would cover most quick-check needs on its own.

**Preference driving this:** per-project settings that live with the repo, not
centralized editor configuration (e.g. `vhdl-project-alist` in
`local-vhdl-proj.el`).

## The actual need

While actively developing an individual file, I want a quick in-editor compile
of *that file* with Questasim `vcom`, errors captured in a `*compilation*`
buffer that `next-error` (`<f1>`) can hop through. Full builds stay with
whatever Questasim `.do` Tcl script the project already provides (Windows; Make
is avoided).

## Key realization

The capability I rely on is **single-file `vcom` + the ModelSim/Questasim error
regexp**, which is *separable* from `vhdl-project-alist`. Projects only ever
bought four things: header `<project>`/`<description>` fields, compilation,
Makefile generation, and source/hierarchy browsing. Only compilation matters
here, and it does not actually require a project.

Two load-bearing pieces, both already global/committed in `vhdl-mode-config.el`:

1. **Error regexp** — `** Error: file(line): ...` parsed into file/line. Lives in
   `vhdl-compiler-alist`, selected by `vhdl-compiler "ModelSim"`.
2. **The compile command** — `vhdl-compile` (`C-c C-k` in vhdl-mode) builds the
   `vcom` invocation from that same alist entry.

Important: **`vhdl-compile` works with `vhdl-project` nil.** With no project it
runs `vcom` in the buffer's `default-directory`, library `work`, installing the
ModelSim error regexp into `compilation-error-regexp-alist` for that compile.
Errors land in `*compilation*`; existing `<f1>` -> `next-error` hops them. That
likely covers ~90% of the need with zero project config.

## The one genuinely per-project datum

Where the `work` library mapping lives — the `modelsim.ini` + compiled `work/`
that each project sets up differently (usually under `sim/`, beside the `.do`
scripts). Single-file `vcom` fails only when it cannot find that mapping.

Clean, transportable fix on Windows/Questasim: point the **`MODELSIM`**
environment variable at the project's `modelsim.ini`. Then `vcom -2008 -work
work file.vhd` resolves the library from anywhere, regardless of layout. Capture
only that path per repo via `.dir-locals.el`:

```elisp
;; <repo>/.dir-locals.el  — the ONLY project-specific bit
((vhdl-mode
  . ((eval . (setenv "MODELSIM"
               (expand-file-name "sim/modelsim.ini"
                 (locate-dominating-file default-directory "sim")))))))
```

`C-c C-k` on any file in that tree then compiles against the library mapping the
project's own `.do` script already built, with error navigation intact. Adopts
the existing sim setup instead of fighting it; nothing project-specific lives in
the Emacs config.

## Why this fits the constraints

- **No Make.** Full builds stay with the project's `.do`; Emacs only does the
  quick single-file pass.
- **No central project maintenance.** The one varying value (the `.ini`
  location) rides in the repo via dir-locals. Could then delete
  `local-vhdl-proj.el` and its `(require 'local-vhdl-proj)`.
- **Reuses existing config.** `vhdl-compiler "ModelSim"` already does the work.

## Caveats

- **dir-locals safety prompts.** `eval` forms (and vars like `vhdl-project`) are
  flagged unsafe on first visit. Persisting approval is awkward because
  `custom-file` is `null-device`; use an allowlist in `vhdl-mode-config.el`
  (`safe-local-variable-values` / `safe-local-eval-forms`) if adopted.
- **Non-standard library name/path.** If a shop maps `work` to a different
  library name or odd path, adjust the `vcom -work <lib>` arg — also just a
  per-repo dir-local string.
- **Lost features.** No vhdl-mode Makefile generation or speedbar source
  hierarchy. Irrelevant given reliance on external sim tooling.

## Lowest-risk experiment before committing to anything

In a project currently being helped on:

1. `M-x setenv RET MODELSIM RET <their>/sim/modelsim.ini`
2. Open a source file in that tree.
3. `C-c C-k` (`vhdl-compile`).
4. Confirm errors parse and `<f1>` / `next-error` hops between them.

If that works, the `.dir-locals.el` snippet above is the entire solution.

## Alternatives considered

- **`compile-command` dir-local + plain `M-x compile`.** Works, but then the
  Questasim error regexp must be added to the global
  `compilation-error-regexp-alist` manually (vhdl-mode would otherwise own it).
  More moving parts than reusing `vhdl-compile`.
- **Keep centralized `vhdl-project-alist`.** Rejected: violates the
  per-project-over-centralized preference and needs editing the Emacs config for
  every new assignment.

## Language server (vhdl_ls)

Same shape as the SystemVerilog setup (`docs/verible.md`), minus the
tree-sitter work: vhdl-mode already does imenu, indentation, templates, and
beautify well, so only the LSP needs to be added.

**Server:** [VHDL-LS / rust_hdl](https://github.com/VHDL-LS/rust_hdl). It gives:
- live syntax and semantic diagnostics (Flymake via Eglot; `M-n` / `M-p`);
- definition, references, and implementation (component <-> entity) (`M-.`,
  `M-?`);
- hover (Eldoc), rename, and workspace symbols.

GHDL's `ghdl-ls` is the alternative. It needs the GHDL toolchain plus Python,
and is less capable for navigation.

The LSP complements `vcom`; it doesn't replace it. vhdl_ls catches most
errors as you type. Single-file `C-c C-k` stays the "does Questa accept it"
check, and the project `.do` script remains the real build.

### Install (Windows)

1. Download `vhdl_ls-x86_64-pc-windows-msvc.zip` from the
   [releases page](https://github.com/VHDL-LS/rust_hdl/releases).
2. Extract it to `~/Programs/vhdl_ls`, **keeping the layout**:
   `bin/vhdl_ls.exe` plus a sibling `vhdl_libraries/` (std, ieee2008,
   synopsys, vital2000). The server finds those libraries relative to the
   binary. Flattening only the top versioned folder is fine; don't move the
   exe out of `bin/` the way Verible was flattened.
3. Add `~/Programs/vhdl_ls/bin` to the user `PATH`. Restart Emacs, then
   confirm with `vhdl_ls --version`.

### Emacs wiring (`site-lisp/vhdl-mode-config.el`)

Eglot has no built-in VHDL entry, so it needs a server entry plus a hook. These
are the lessons carried over from the Verible setup:

```elisp
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(vhdl-mode . ("vhdl_ls"))))

(defun my-vhdl-eglot-setup ()
  "Start Eglot for VHDL, keeping vhdl-mode's own imenu."
  (require 'eglot)
  ;; Server document symbols would replace vhdl-mode's imenu index.
  (setq-local eglot-stay-out-of (cons 'imenu eglot-stay-out-of))
  (eglot-ensure))
(add-hook 'vhdl-mode-hook #'my-vhdl-eglot-setup)
```

- **imenu:** keep vhdl-mode's index (above). Verible's symbols replaced the
  major mode's imenu, and vhdl_ls would do the same.
- **Eldoc:** vhdl_ls advertises hover, so Eglot's Eldoc works without the
  custom definition-lookup function Verible needed. If the hover markdown is
  too tall in the echo area, set `eldoc-echo-area-use-multiline-p` buffer-locally.
- **Keys:** vhdl-mode doesn't bind `M-.`, `M-?`, `M-n`, or `M-p`, so no
  unbinding is needed (verilog-mode's `M-?` was the exception).
- **Completion:** Eglot adds a CAPF. Check that it doesn't fight vhdl-mode's
  electric templates or YASnippet's `C-<tab>`.
- **Formatting:** keep vhdl-mode beautify (`C-c M-b`). Don't route
  `eglot-format` to the server unless its output matches house style.

### Per-project configuration

The server merges three config files, later ones overriding earlier:

1. `~/.vhdl_ls.toml` for global defaults;
2. the file named by `$VHDL_LS_CONFIG`;
3. `vhdl_ls.toml` in the workspace root, i.e. the project.el root (normally
   the git root).

This fits the per-project preference. Put defaults in `~/.vhdl_ls.toml`:

```toml
standard = "2008"

[lint]
unnecessary_work_library = false
```

Put the library mapping in each repo's `vhdl_ls.toml`:

```toml
[libraries]
my_lib.files = ['src/**/*.vhd', 'sim/**/*.vhd']
my_lib.exclude = ['src/**/*_old.vhd']

# Vendor primitives: analysed for navigation, lints suppressed.
unisim.files = ['%XILINX_VIVADO%/data/vhdl/src/unisims/unisim_VCOMP.vhd']
unisim.is_third_party = true
```

- **`work` is reserved.** Name the library what the `.do` script calls it.
  Code that refers to `work.` still resolves, because vhdl_ls treats `work`
  as "the file's own library".
- **Duplicate mapping.** The library-to-files mapping now lives in both the
  `.do`/`modelsim.ini` and `vhdl_ls.toml`. Globs keep the TOML nearly
  maintenance-free. If drift becomes a problem, generating the TOML from the
  `.do` file list is a small script.
- **Paths** are relative to the TOML file. On Windows, environment variables
  use `%NAME%` syntax (useful for vendor install roots).
- **Unsupported constructs** (e.g. PSL) can be fenced with
  `-- vhdl_ls off` / `-- vhdl_ls on`.
- A copy-ready `docs/vhdl_ls/.vhdl_ls.toml` template, like
  `docs/verible/`, belongs here once the setup is in use.

### Not covered by vhdl_ls

- **House naming style** (`*_i`/`*_o`, `C_*`, `G_*`, `*_PROC`, ...). vhdl_ls has
  no naming-convention rules. [VSG](https://github.com/jeremiah-c-leary/vhdl-style-guide)
  (`pip install vsg`) can enforce them through a per-project config. It would
  run as a separate Flymake backend, the counterpart of Verible lint.
- **tree-sitter.** Not needed; vhdl-mode is better than the available
  `vhdl-ts-mode` for editing.
- **`vhdl-ext`** (gmlarumbe) wraps the Eglot setup above, among other things.
  It isn't worth the dependency for a few lines.
