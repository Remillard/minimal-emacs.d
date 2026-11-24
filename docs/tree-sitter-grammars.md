# Tree-sitter Grammars on Windows

How to build tree-sitter grammars from source on a Windows machine that starts with little more than Git. This is required for grammars that are not in the prebuilt `tree-sitter-langs` bundle, such as `systemverilog` for `verilog-ts-mode`.

The tooling lives in `site-lisp/my-treesit-grammars.el`. Languages to build from source are listed in `my-treesit-grammar-recipes` in `post-init.el`.

## How it works

`M-x my-treesit-build-grammar` runs this pipeline asynchronously and logs to `*treesit-build*`:

1. `git clone` the grammar repository (shallow unless the recipe pins a commit hash).
2. If `src/parser.c` is missing or newer than the ABI this Emacs can load (`(treesit-library-abi-version)`; Emacs 30.1 => 14), regenerate it with `tree-sitter generate --abi N`. This runs `grammar.js` under **Node.js**, after an `npm install` if the grammar requires other grammars.
3. `tree-sitter build` compiles the parser into `libtree-sitter-LANG.dll`. On Windows the CLI uses **MSVC** and finds it on its own (no `vcvars64.bat` required).
4. The DLL is copied into `var/tree-sitter/`.

## Required tools

| Tool | Purpose | Needed when |
|---|---|---|
| Git | Clone grammar repositories | Always |
| tree-sitter CLI | Regenerate and compile grammars | Always |
| Build Tools for Visual Studio 2022 | MSVC compiler, linker, Windows SDK | Always |
| Node.js LTS | Execute `grammar.js` during regeneration | When the grammar ABI is too new (true for `systemverilog` on Emacs 30.1) |

## Setup (Windows 11)

Run in PowerShell. Open a **new** terminal after the `winget` installs so `PATH` updates take effect, and restart Emacs so it inherits the new `PATH`.

### 1. Build Tools for Visual Studio 2022

The free, command-line-only MSVC toolchain (~2-3 GB). The full Visual Studio IDE is not needed; an existing Visual Studio installation with the C++ workload also works.

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

This installs the *Desktop development with C++* workload (MSVC v143 and the Windows 11 SDK). The installer may take a while and can run silently; wait for `winget` to return.

### 2. Node.js LTS

```powershell
winget install OpenJS.NodeJS.LTS
```

### 3. tree-sitter CLI

The CLI is a single executable distributed as a raw gzip (not a tar archive):

```powershell
$dir = Join-Path $HOME 'Programs\tree-sitter'
New-Item -ItemType Directory -Force $dir | Out-Null
$gz  = Join-Path $env:TEMP 'tree-sitter.gz'
curl.exe -sL -o $gz https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-windows-x64.gz
$in  = [IO.File]::OpenRead($gz)
$z   = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
$out = [IO.File]::Create((Join-Path $dir 'tree-sitter.exe'))
$z.CopyTo($out); $out.Close(); $z.Close(); Remove-Item $gz
```

It does not need to be on `PATH`; Emacs finds it through `local-tree-sitter-cli`.

### 4. Verify

```powershell
git --version
node --version
& "$HOME\Programs\tree-sitter\tree-sitter.exe" --version
& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property displayName
```

The last command should print the Build Tools (or Visual Studio) product name. Empty output means the C++ workload is missing.

### 5. Configure Emacs

In `site-lisp/local-settings.el` (copied from `local-settings.el.template`), confirm `local-tree-sitter-cli` points at the CLI. The template default on Windows is:

```elisp
(defvar local-tree-sitter-cli
  (pcase sysinfo-os-family
    ('Windows "~/Programs/tree-sitter/tree-sitter.exe")
    (_        (executable-find "tree-sitter")))
  "Path to the tree-sitter CLI, or nil if not installed.")
```

Existing `local-settings.el` files created before this variable existed need it added by hand.

### 6. Build grammars

1. `M-x my-treesit-update-grammars` — install the prebuilt bundle (all other languages).
2. `M-x my-treesit-build-all-grammars` — build everything in `my-treesit-grammar-recipes`. Use `M-x my-treesit-build-grammar` for a single language.
3. Verify, e.g. `M-: (treesit-language-available-p 'systemverilog)` returns `t`.

The prebuilt updater skips languages in `my-treesit-grammar-recipes`, so the two commands can be run in either order.

## Adding a grammar

Add a recipe to `my-treesit-grammar-recipes` in `post-init.el` and run `M-x my-treesit-build-grammar`:

```elisp
(setq my-treesit-grammar-recipes
      '((systemverilog "https://github.com/gmlarumbe/tree-sitter-systemverilog")
        ;; (LANG URL [REVISION SOURCE-DIR])
        ;; REVISION: branch, tag, or commit hash.  SOURCE-DIR defaults to "src";
        ;; multi-grammar repositories need e.g. "typescript/src".
        ))
```

`LANG` must match the name the major mode requests (e.g. `verilog-ts-mode` uses `systemverilog`), since Emacs loads `libtree-sitter-LANG.dll` and the `tree_sitter_LANG` symbol inside it. Machine-only recipes can go in `local-treesit-language-source-alist` instead.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `tree-sitter CLI not found` | `local-tree-sitter-cli` unset or wrong path. |
| `Node.js not found; required to regenerate` | Install Node.js and restart Emacs so it sees the new `PATH`. |
| `tree-sitter build` fails looking for a compiler or `link.exe` | C++ workload missing; re-run the Build Tools install and check with `vswhere` (step 4). |
| `file-error ... restart Emacs and rebuild` at install | The grammar DLL is loaded and locked by Windows. Restart Emacs, rebuild before opening a buffer that uses it. |
| `treesit-load-language-error ... version-mismatch` | DLL built at an ABI this Emacs cannot load. Rebuild with `my-treesit-build-grammar`, which regenerates at the supported ABI. |
| Failed build | The temporary work directory is kept and its path logged in `*treesit-build*` for inspection. |

DLLs built with MSVC depend on `VCRUNTIME140.dll` (the Visual C++ runtime). It is installed with the Build Tools; copying a built DLL to a machine without the runtime requires the [Visual C++ Redistributable](https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist).

Grammar DLLs in `var/tree-sitter/` are not committed (`var/*` is ignored), so each machine builds its own.
