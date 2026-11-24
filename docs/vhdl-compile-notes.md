# VHDL in-editor compilation without centralized project config

**Status:** Parked / not urgent. Current workflow (vhdl-mode projects, or manual
compile) is adequate. Revisit if bouncing between projects makes per-file
compile friction worth solving.

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
