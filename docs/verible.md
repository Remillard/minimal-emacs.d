# Verible (SystemVerilog LSP, Lint, Format)

[Verible](https://github.com/chipsalliance/verible) provides the language server used by Eglot in `verilog-mode` and `verilog-ts-mode`. Configuration lives in `site-lisp/verilog-mode-config.el`.

What it supplies in Emacs:

| Feature | Source |
|---|---|
| Lint diagnostics | Flymake via Eglot (`M-n` / `M-p` to step) |
| Go to definition / references | `M-.` / `M-?` |
| Declaration prototype at point | Eldoc (definition request + tree-sitter) |
| Formatting | `eglot-format-buffer` / `eglot-format` |
| Rename | `eglot-rename` |

imenu is deliberately left to `verilog-ts-mode`; Verible's document symbols list only variables.

## Install (Windows)

1. Download the latest `verible-*-win64.zip` from the [releases page](https://github.com/chipsalliance/verible/releases).
2. Extract it so the executables sit directly in `~/Programs/verible` (flatten the versioned subdirectory).
3. Add `~/Programs/verible` to the user `PATH`, open a new terminal, and confirm with `verible-verilog-ls --version`.
4. Restart Emacs so it inherits the new `PATH`.

Exit Emacs before replacing an existing install; a running `verible-verilog-ls.exe` locks the directory. Renaming the old directory (e.g. `verible-3946`) first keeps a fallback.

On macOS/Linux, install from the release tarball or a package manager and make sure `verible-verilog-ls` is on `PATH`.

## Configuration files

The files in `docs/verible/` are the single source of truth. Symlink them into a common ancestor of your sources (e.g. `C:\proj`); a real file in a project root overrides the ancestor link for that tree. Both files are found only by searching upward from the source file; there is no fallback to `~`. Both files support `#` comments.

On Windows, creating symlinks requires Developer Mode (Settings > System > For developers) or an elevated shell. Do not use hard links: Emacs saves and git checkouts replace the file, which silently breaks the link.

```powershell
foreach ($n in '.rules.verible_lint', '.verible_format') {
  New-Item -ItemType SymbolicLink -Path "C:\proj\$n" -Target "$HOME\.config\emacs\docs\verible\$n"
}
```

| File | Purpose | How it is found |
|---|---|---|
| `.rules.verible_lint` | Lint rule configuration | Verible's `--rules_config_search`: nearest file searching upward from the source file |
| `.verible_format` | Formatter flags, one per line | `my-verible-ls-contact`: nearest file via `locate-dominating-file`, passed as `--flagfile` |
| `verible.filelist` | Source list for cross-file definition/references | Verible looks in the workspace root (the project root Eglot uses) |

`.verible_format` is a local convention; Verible has no standard formatter config file. Do not put `--inplace` in it: the language server rejects it and exits.

The formatter file is read when the server starts, and lint rules may be cached by the server. After editing either, run `M-x eglot-reconnect`.

### Lint rules template

The template enforces the house naming style:

- `localparam` constants: `C_` prefix, ALL_CAPS.
- Generate block labels: ALL_CAPS with a `_GEN` suffix (replaces Verible's `g_`/`gen_` prefix default).
- Line length: 200 (Verible default is 100), matching `--column_limit=200` in `.verible_format` so alignment with trailing comments is preserved.
- Ports end in `_i`, `_o`, or `_io`; active-low as `*_n_i`, `*_n_o`.
- Types end in `_t` (enums may also use `_e`): Verible defaults, no config needed.

List all rules and their parameters with `verible-verilog-lint --help_rules=all`. Rule syntax: `+rule` / `-rule` to enable or disable, `rule=param:value;param2:value` to configure.

### verible.filelist

Without a file list, navigation only resolves symbols in open files. Generate one at the project root:

```powershell
Get-ChildItem -Recurse -Include *.sv,*.svh,*.v |
  ForEach-Object { (Resolve-Path -Relative $_.FullName) -replace '^\.\\','' -replace '\\','/' } |
  Set-Content verible.filelist
```

## Command line

```powershell
verible-verilog-lint --rules_config_search file.sv
verible-verilog-format --flagfile=$HOME\.config\emacs\docs\verible\.verible_format --inplace file.sv
```
