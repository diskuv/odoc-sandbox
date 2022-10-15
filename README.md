# odoc-sandbox

This project is a home ("sandbox") for experiments on [odoc](https://github.com/ocaml/odoc).

The experiment results are rendered at [https://diskuv.github.io/odoc-sandbox/](https://diskuv.github.io/odoc-sandbox/).

## Usage

To modify the sandbox you will need to:

1. Check out the source code locally on your computer
2. Install the system requirements for your operating system:

   | System Requirements              |
   | -------------------------------- |
   | [macOS](#requirements-macos)     |
   | [Windows](#requirements-windows) |

   > Linux users: Please adapt the [macOS](#requirements-macos) requirements and submit a PR to update
   >  the install instructions!

Then you can use:

| Command                                                                              | What                                                |
| ------------------------------------------------------------------------------------ | --------------------------------------------------- |
| `conda run -n odoc-sandbox make`                                                     | setup an Opam switch and run the experiments        |
| `conda run -n odoc-sandbox make ide`                                                 | setup an Opam switch with OCaml LSP and ocamlformat |
| `conda run -n odoc-sandbox --live-stream make server`                                | see the resulting HTML at http://localhost:8000     |
| `conda run -n odoc-sandbox --live-stream dune build @runtest --auto-promote --watch` | autorun the experiments                             |

You will find it useful to do the `... make server` and the `... dune build ... --watch` commands in parallel; you can tweak
an experiment and see the result by refreshing the page.

## Directory Structure

| Directory             | Purpose                                                  |
| --------------------- | -------------------------------------------------------- |
| `content/`            | Source `.mli` and `.mld` content                         |
| `exp/NNN-name/`       | The experiments, numbered from simplest to most advanced |
| `exp/res/odoc-theme/` | CSS and JS provided by odoc                              |
| `exp/res/index/`      | CSS and JS needed for hand-crafted index.html            |

Each experiment copies what it needs from `content/`.

## Requirements: macOS

| macOS Packages | Installing                         |
| -------------- | ---------------------------------- |
| pandoc         | See [macOS: python](#macos-python) |
| sphinx         | See [macOS: sphinx](#macos-sphinx) |

### macOS: python

FIRST, install the Python package manager "miniconda" (skip this step if you have already installed miniconda or anaconda):

```console
$ if ! command -v conda; then
    brew install miniconda
  fi

...
==> Linking Binary 'conda' to '/opt/homebrew/bin/conda'
🍺  miniconda was successfully installed!
```

SECOND (optional!) if you like conda in your PATH you can do:

```console
$ conda init "$(basename "${SHELL}")"

...
==> For changes to take effect, close and re-open your current shell. <==
```

THIRD, close and re-open your current shell (ex. Terminal)

FOURTH, run the following:

```console
$ conda update -n base -c defaults conda
$ if ! conda list -q -n odoc-sandbox &>/dev/null; then
    conda create --yes -n odoc-sandbox python=3.8
  fi
$ conda install -c conda-forge --yes -n odoc-sandbox 'python>=3.8' sphinx pandoc
```

*The above command can be run repeatedly; you can use it for upgrading Python dependencies.*

### macOS: sphinx

We avoid the version from `brew install sphinx` since it says:

```
Warning: sphinx has been deprecated because it is using unsupported v2 and source for v3 is not publicly available!
```

Just follow the [Python installation instructions](#macos-python)!

## Requirements: Windows

| Windows Packages | Installing                         |
| ---------------- | ---------------------------------- |
| make             | See [Win32: make](#win32-make)     |
| pandoc           | See [Win32: python](#win32-python) |
| sphinx           | See [Win32: python](#win32-python) |

### Win32: make

`make` is available on Windows with Cygwin or MSYS2.

> If you installed Windows DKML, you can use `with-dkml make` to replace `make`. For example,
> run:
> ```bash
> conda run -n odoc-sandbox with-dkml make
> ```
> instead of
> ```bash
> conda run -n odoc-sandbox make
> ```

### Win32: python

FIRST download and install from https://docs.conda.io/en/latest/miniconda.html

SECOND, in **PowerShell** do the following:

```powershell
PS> &conda update -n base -c defaults conda
PS> &conda list -q -n odoc-sandbox | Out-Null
    if ($LASTEXITCODE) {
      &conda create -y -n odoc-sandbox -c conda-forge 'python=3.8'
    }

PS> &conda install -c conda-forge --yes -n odoc-sandbox 'python>=3.8' sphinx pandoc
```
