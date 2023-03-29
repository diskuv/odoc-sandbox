all: opam-packages assets
.PHONY: all

# --------------- Windows (MSYS2/Cygwin/native) setup ---------------
ifeq ($(OS),Windows_NT)
EXEEXT = .exe
else
EXEEXT =
endif

# -------------------- Diskuv OCaml / MSYS2 setup -------------------
MSYS2_CLANG64_PREREQS =
PACMAN_EXE = $(wildcard /usr/bin/pacman)
CYGPATH_EXE = $(wildcard /usr/bin/cygpath)
OPAMSWITCH := $(CURDIR)
ifneq ($(CYGPATH_EXE),)
ifneq ($(PACMAN_EXE),)
OPAMSWITCH := $(shell $(CYGPATH_EXE) -aw $(CURDIR))
MSYS2_CLANG64_PACKAGES = mingw-w64-clang-x86_64-pkg-config
MSYS2_CLANG64_PREREQS = /clang64/bin/pkg-config.exe
$(MSYS2_CLANG64_PREREQS):
	$(PACMAN_EXE) -S --needed --noconfirm $(MSYS2_CLANG64_PACKAGES)
endif
endif

# --------------------------- Opam switch ---------------------------

SWITCH_ARTIFACTS = _opam/.opam-switch/switch-config
switch: $(SWITCH_ARTIFACTS)
.PHONY: switch
$(SWITCH_ARTIFACTS):
	export OPAMYES=1 && if [ -x "$$(opam var root)/plugins/bin/opam-dkml" ]; then \
		dkml init ; \
	else \
		opam switch create . --empty --no-install --repos diskuv=git+https://github.com/diskuv/diskuv-opam-repository.git#main,default=https://opam.ocaml.org; \
	fi

PIN_ARTIFACTS = _opam/.pin.depends
pins: $(PIN_ARTIFACTS)
$(PIN_ARTIFACTS): $(SWITCH_ARTIFACTS) $(MSYS2_CLANG64_PREREQS) Makefile
	export OPAMYES=1 OPAMSWITCH='$(OPAMSWITCH)' && \
	opam pin tezt git+https://gitlab.com/nomadic-labs/tezt.git#3.0.0 --no-action && \
	touch $@


OPAMPKGS_ARTIFACTS = _opam/bin/dune$(EXEEXT) _opam/bin/odoc$(EXEEXT)
opam-packages: $(OPAMPKGS_ARTIFACTS)
.PHONY: opam-packages
$(OPAMPKGS_ARTIFACTS): $(SWITCH_ARTIFACTS) $(MSYS2_CLANG64_PREREQS)
	export OPAMYES=1 OPAMSWITCH='$(OPAMSWITCH)' && \
	opam install ./odoc-sandbox.opam --with-test --with-doc --deps-only
	touch $@

IDE_ARTIFACTS = _opam/bin/ocamlformat$(EXEEXT) _opam/bin/ocamlformat-rpc$(EXEEXT) _opam/bin/ocamllsp$(EXEEXT)
ide: $(IDE_ARTIFACTS)
.PHONY: ide
$(IDE_ARTIFACTS): $(SWITCH_ARTIFACTS) $(MSYS2_CLANG64_PREREQS)
	export OPAMYES=1 OPAMSWITCH='$(OPAMSWITCH)' && \
	opam install ocamlformat.0.24.1 ocaml-lsp-server
	touch $@

# ------------------------------ Assets -----------------------------

.PHONY: assets
assets: exp/res/odoc-theme/highlight.pack.js exp/res/odoc-theme/odoc.css exp/res/pygments/pygments.css

# As of odoc 2.2.0 finding highlight.pack.js is brittle (relies on the opam switch sources/).
# Before that, it was in odoc's share/ folder which was reliable.
exp/res/odoc-theme/highlight.pack.js: $(OPAMPKGS_ARTIFACTS)
	export OPAMYES=1 OPAMSWITCH='$(OPAMSWITCH)' && \
	PREFIX=$$(opam var prefix) && \
	opam exec -- diskuvbox copy-file "$$PREFIX"/.opam-switch/sources/odoc.*/src/html_support_files/highlight.pack.js $@

exp/res/odoc-theme/odoc.css: $(OPAMPKGS_ARTIFACTS)
	export OPAMYES=1 OPAMSWITCH='$(OPAMSWITCH)' && \
	ODOC_SHARE=$$(opam var odoc:share) && \
	opam exec -- diskuvbox copy-file "$$ODOC_SHARE/odoc-theme/default/odoc.css" $@

#	Have a look at the styles at https://pygments.org/styles/ or just run pygmenter -L
exp/res/pygments/pygments.css:
	pygmentize -S rrt -f html -a pre.code > $@

# ------------------------ Development Tasks ------------------------

SERVER_PORT = 8000

.PHONY: test
test: $(OPAMPKGS_ARTIFACTS)
	export OPAMYES=1 OPAMSWITCH='$(OPAMSWITCH)' && \
	opam exec -- dune build --display=short @runtest @doc

.PHONY: server
server: assets
	echo "Starting web server on port $(SERVER_PORT). Change the port with the Makefile variable -D SERVER_PORT=xxx"
	conda run -n odoc-sandbox --live-stream python3 -m http.server $(SERVER_PORT) --directory exp
