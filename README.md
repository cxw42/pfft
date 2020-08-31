# PDF From Formatted Text: markdown to PDF with fewer dependencies

I think TeX, LaTeX, and Pandoc are fantastic tools!  However, I sometimes
need a markdown-to-PDF converter with fewer dependencies.  Pfft is that tool.

Pfft:

- Doesn't need a Web browser --- it doesn't use HTML
- Doesn't need a build system --- it comes with an autoconf-generated build
  script
- Doesn't need a separate rendering library --- it uses pangocairo, which
  is standard on GNOME systems.

## Installing from a source tarball

(Package names may differ --- these are for Ubuntu)

    $ sudo apt install -y libpango1.0-dev libgee-0.8-dev libgstreamer1.0-dev
    $ tar xvf pfft-VERSION.tar.gz
    $ cd pfft-VERSION
    $ ./configure && make -j4 && sudo make install

For the HTML documentation, run `make html`, then open
`doc/valadoc/pfft/index.htm`.

## Hacking on Pfft

All files are UTF-8, no BOM.

### Building from Git

Tested on Lubuntu Eoan, with additional CI builds on Ubuntu Bionic.

Install Vala:

    $ sudo apt install -y build-essential valac valadoc graphviz-dev help2man

(NOTE: you may be able to skip this step) Install the latest stable [valac]:

    $ git clone https://gitlab.gnome.org/GNOME/vala.git
    $ cd vala
    $ git checkout 0.48.6   # or whatever the latest stable is
    $ ./autogen.sh && make -j4 && sudo make install

Install development dependencies for pfft:

    $ sudo apt install -y libpango1.0-dev libgee-0.8-dev libgstreamer1.0-dev autotools-dev uncrustify perl lcov

Initialize submodules:

    $ git submodule update --init --recursive

Build:

    $ ./bootstrap
    $ ./configure && make -j4

Note: `libpango1.0-dev` pulls in Pango, Cairo, and pangocairo.

### Testing

`make test` or `make check` at the top level.

In GLib 2.62+, the default output format is TAP.  Therefore, you can do
`make build-tests && prove`.

### Checking code coverage

    ./configure --enable-code-coverage && make -j4 check-code-coverage

This will print a summary to the console.  For the full report, open
`pfft-<VERSION>-coverage/index.html` in a Web browser.

### Making a release

    $ make distcheck

This will build `pfft-VERSION.tar.gz` and check it.

### Pull requests

PRs are welcome!  I prefer PRs with one commit that adds tests and a subsequent
commit that adds the code (TDD).  However, that is not required.

Before submitting a PR, please run `make prep`.  This will:

- `make prettyprint` (conform to the coding style)
- `make check` (must pass the tests!)
- `make all build-tests && prove -v` (runs the tests a different way)
- `make distcheck` (make sure the tarball will build)

### Notes on compiling Vala sources

- All the .vala files are run through a single pass of `valac`.
  However, the resulting C files are compiled by separate invocations of gcc.
- The valac invocation happens in the _source_ tree.  I think this is because
  the dist tarball includes the generated C files.  Therefore, references
  to the generated .h and .vapi files require `$(srcdir)`.
- Even if you `make clean` or `make distclean`, generated .c files will still
  be left in the tree.  To remove the generated C files,
  `make maintainer-clean`.

## Thanks

- <https://github.com/stefantalpalaru/vala-skeleton-autotools>
- <https://github.com/D3Engineering/d3-jetson-bsp>

## Legal

Most of pfft is BSD-3-clause (see file `LICENSE`).  The files in `src/logging`
are LGPL 2.1+ (see file `LGPL-2.1`).

[valac]: https://wiki.gnome.org/Projects/Vala
