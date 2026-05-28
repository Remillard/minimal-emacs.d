# Copilot Instructions for minimal-emacs.d

This is a personal Emacs configuration for Mark Norton (GitHub: Remillard), built on top of [James Cherti's minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d) framework. The primary use case is **FPGA/HDL development** (VHDL, SystemVerilog) with supporting tooling for Python, MATLAB, Tcl, and Emacs Lisp.

## Build and CI

The CI pipeline (`.github/workflows/ci.yml`) byte-compiles the framework init files against Emacs 29.1, 29.4, and 30.1:

```bash
# Compile early-init.el
emacs -batch -L . --eval "(progn (setq byte-compile-error-on-warn t) \
  (setq byte-compile-warnings '(not obsolete free-vars)))" \
  -f batch-byte-compile early-init.el

# Compile init.el (requires early-init.el to be loaded first)
emacs -batch -L . --eval "(progn (setq byte-compile-error-on-warn t) \
  (setq byte-compile-warnings '(not obsolete free-vars)) \
  (load \"early-init.el\" nil t t))" \
  -f batch-byte-compile init.el
```

**Only `early-init.el` and `init.el` are compiled by CI.** The user files (`pre-*.el`, `post-*.el`) are excluded from byte-compilation (marked `no-byte-compile: t`).

## Architecture: Init File Loading Order

The framework intercepts Emacs' standard startup and loads files in this sequence:

```
pre-early-init.el   ← User customizations BEFORE early-init.el framework code
early-init.el       ← Framework: GC tuning, UI suppression, native-comp, package.el setup
post-early-init.el  ← User customizations AFTER early-init.el (currently nearly empty)
pre-init.el         ← User customizations BEFORE init.el: Elpaca bootstrap lives here
init.el             ← Framework: Emacs defaults (editing, scrolling, files, eglot, etc.)
post-init.el        ← User customizations AFTER init.el: ALL packages installed here
```

The hook that wires this together is `minimal-emacs-load-user-init` defined in `early-init.el`.

## Directory Layout

- `site-lisp/` — Manually managed packages and local config (on `load-path` as `user-site-lisp-dir`)
  - `vhdl-mode-3.39.3/` — Standalone VHDL mode (loaded directly, not via Elpaca)
  - `vhdl-mode-config.el` — All VHDL mode settings, models, and project config
  - `local-settings.el` — **Not committed.** Machine-local vars: name, email, VHDL company, font, nerd-icons font family, theme, temp dir, notes dir/file, shell binary. Uses `sysinfo-os-family` with `pcase` for cross-platform defaults. Copy from `local-settings.el.template`.
  - `local-vhdl-proj.el` — **Not committed.** Machine-local VHDL project definitions. Copy from `local-vhdl-proj.el.template`.
  - `sysinfo/` — OS detection library providing `sysinfo-os-family` (`Windows`, `macOS`, `Linux`, etc.) and `sysinfo-os-type` (e.g., `WSL`). Loaded in `post-init.el` before `local-settings.el` so that `pcase sysinfo-os-family` expressions in `local-settings.el` evaluate correctly.
  - `Emacs-MATLAB-Mode/`, `yasnippet/`, `yasnippet-snippets/`, `vscode-cp-proxy/` — Git submodules
- `var/` — Runtime data directory (`user-emacs-directory` is redirected here to keep the repo root clean). Contains `elpa/`, `elpaca/`, `recentf`, `savehist`, etc.
  - `var/snippets/` — **Tracked in git.** Custom YASnippet snippets.
  - `var/tree-sitter/` — **Tracked in git.** Tree-sitter grammar files.
- `autosave/` — Auto-save files (not tracked)

## Key Conventions

### `user-emacs-directory` Redirection

`pre-early-init.el` redirects `user-emacs-directory` to `var/` so Emacs packages and runtime state do not clutter the repo root. The original directory is preserved in `user-emacs-orig-dir`. Always use `user-emacs-orig-dir` when referring to the repo root from Lisp, and `user-site-lisp-dir` for `site-lisp/`.

### Package Manager: Elpaca (not package.el)

`pre-init.el` bootstraps [Elpaca](https://github.com/progfolio/elpaca) and sets `minimal-emacs-package-initialize-and-refresh nil` to prevent the framework from calling `package-initialize`. All packages in `post-init.el` use `use-package` backed by Elpaca. `elpaca-no-symlink-mode` is active (Windows compatibility).

Packages not managed by Elpaca (loaded via `require` directly from `site-lisp/`):
- `vhdl-mode` — loaded from `site-lisp/vhdl-mode-3.39.3/`
- `yasnippet` and `yasnippet-snippets` — loaded from `site-lisp/` submodules
- `matlab-autoload` — loaded from `site-lisp/Emacs-MATLAB-Mode/`

### Local Settings Pattern

Any machine-specific value (paths, names, font, theme) is declared as a `defvar` in `site-lisp/local-settings.el` and referenced by name in `post-init.el`. When adding new machine-local configuration:
1. Add a `defvar` to `site-lisp/local-settings.el.template` with a safe default. For values that differ by OS (fonts, shell path, etc.), use `(pcase sysinfo-os-family ('Windows ...) ('macOS ...) (_ ...))` as the default expression — `sysinfo` is guaranteed loaded before `local-settings.el`.
2. Reference the variable name in `post-init.el` or wherever needed.
3. Never hardcode machine-specific paths in committed files.

### Custom.el is Disabled

`(setq custom-file null-device)` discards all Emacs Customize writes to `/dev/null`. All configuration must be done in Lisp — never rely on `M-x customize` to persist settings.

### VHDL Configuration

VHDL mode is loaded from `site-lisp/vhdl-mode-3.39.3/` (not from ELPA/Elpaca). All settings live in `site-lisp/vhdl-mode-config.el`, which is `require`'d from `post-init.el`. Machine-local project definitions go in `site-lisp/local-vhdl-proj.el` (not committed; copy from template).

VHDL standard: **VHDL-2008** (`vhdl-standard '(8 nil)`). Compiler target: **ModelSim/Questasim**. Direct instantiation is always used (`vhdl-use-direct-instantiation 'always`). Reset is active-high (`vhdl-reset-active-high t`).

The file header template and enforced naming scheme (documented in `vhdl-mode-config.el`):

| Signal type | Convention |
|---|---|
| Active low | `*_n` |
| Clocks | `clk`, `clk*`, `*_clk` |
| Resets | `*_rst`, `*_reset` |
| Generics | `G_*` |
| Constants | `C_*` |
| User-defined types | `*_type`, `T_*` |
| Inputs | `*_i` |
| Outputs | `*_o` |
| Bidirectional | `*_io`, `io_*` |
| Combinatorial signals | `*_s` |
| Asynchronous signals | `*_a` |
| Shift registers | `*_sr` |
| Register delays | `*_d#` |
| Clock enables | `*_ce` |
| Processes | `*_PROC` |
| Instance names | `u_<entity>_<index>` (via `vhdl-instance-name`) |

Built-in VHDL process templates (invoked via `C-c C-m` in vhdl-mode): sync process with sync reset (`spsr`), sync process with async reset (`spar`), combinatorial process (`cp`), testbench process (`tp`), IEEE library block (`ieee`), TextIO libraries (`textio`).

### Verilog/SystemVerilog Configuration

`verilog-mode` is built into Emacs (`:ensure f`). `verilog-ext` (from Elpaca) is layered on top and hooked to `verilog-mode` with `beautify` and `imenu` features enabled. Indentation is 4 spaces at all levels. Typedef alignment regexp matches the `*_t` suffix convention (`verilog-align-typedef-regexp`).

### Tcl File Associations

Several FPGA-specific file extensions are mapped to `tcl-mode` in `post-init.el`:
- `.qsf` — Quartus Settings Files
- `.xdc` — Xilinx constraint files
- `.do` — ModelSim/Riviera macro files
- `.sdc` — Timing constraint files

### LSP via Eglot

Eglot is built-in and currently configured only for **Python** (`python-mode` hook, `pylsp` server). LSP for VHDL and Verilog is not yet wired in. The pylsp workspace configuration enables: isort, pycodestyle, pyflakes, pydocstyle, mccabe; autopep8 and yapf are disabled.

### YASnippet

`yasnippet` and `yasnippet-snippets` are loaded from `site-lisp/` submodules (not Elpaca). `yas-global-mode` is enabled. Snippet expansion is bound to `C-<tab>`. Custom snippets go in `var/snippets/` (tracked in git; excluded from the general `var/*` gitignore rule).

### AI Integration (gptel)

`gptel` configuration with a `cs45-fpga-hdl` preset via `vscode-cp-proxy` (GitHub Enterprise Copilot backend) is present but **currently commented out** in `post-init.el`. The proxy module lives in `site-lisp/vscode-cp-proxy/` (git submodule). When re-enabled, the preset targets Claude Sonnet and is optimized for FPGA/HDL tasks.

### compile-angel

`compile-angel-on-load-mode` is active globally. It auto-compiles `.el` files before they load. The four user init files (`pre/post-early-init.el`, `pre/post-init.el`) are excluded from this to avoid complications with `use-package` macro expansion order.

### Debugging Init Files

`(setq debug-on-error t)` is set in `pre-early-init.el` and left enabled intentionally for development. Emacs can also be started with `emacs --debug-init` for backtrace output on startup errors.
