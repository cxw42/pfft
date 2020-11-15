# Contributing to pfft

**Note:** Please do not use any code from Stack Overflow.  This project uses
under a permissive open-source license, and I would have to change to a
copyleft license if we used code from Stack Overflow.

## Overview

Pfft is written in [Vala](https://wiki.gnome.org/Projects/Vala), which is
a C/C#-like programming language.  A good tutorial by naaando starts
[here](https://naaando.gitbooks.io/the-vala-tutorial/content/en/2-first-program/).

Pfft currently only runs on UNIX-like systems.  I welcome contributions to
support more platforms!  (Please don't change the build system for Linux,
though.)  The instructions below are for Ubuntu.

## Building from Git

Tested on Lubuntu Eoan, with additional CI builds on Ubuntu Bionic.

Fork and clone this repo.  Then:

1. Install build dependencies, including the version of Vala packaged for your
   OS.  For example, on Ubuntu:

       $ sudo apt install -y build-essential valac valadoc graphviz-dev help2man

2. Install development dependencies for pfft:

       $ sudo apt install -y libpango1.0-dev libgee-0.8-dev libgstreamer1.0-dev autotools-dev uncrustify perl lcov

3. Install Vala 0.48 or higher.  The easiest way is to use the
   [Vala Next PPA](https://launchpad.net/~vala-team/+archive/ubuntu/next):

       $ sudo add-apt-repository -y ppa:vala-team/next
       $ sudo apt update
       $ sudo install valac

   Alternatively, you can build from source:

       $ git clone https://gitlab.gnome.org/GNOME/vala.git
       $ cd vala
       $ git checkout 0.48.6   # or whatever the latest stable is
       $ ./autogen.sh && make -j4 && sudo make install

4. In your clone of this repo, initialize submodules:

       $ git submodule update --init --recursive

5. Build:

       $ ./bootstrap
       $ ./configure && make -j4

Note: `libpango1.0-dev` pulls in Pango, Cairo, and pangocairo.

## Testing

`make test` or `make check` at the top level.

In GLib 2.62+, the default output format is TAP.  Therefore, you can do
`make build-tests && prove`.

## Checking code coverage

In the top level of the source tree, run `./coverage.sh`.  Note
that this will change your configuration (it re-runs `./configure`).
Accordingly, all arguments to `coverage.sh` are passed to `configure`.

Once you have run `coverage.sh`, you can retest without reconfiguring by
running `make -j check-code-coverage`.

Checking coverage will print a summary to the console.  For the full report,
open `pfft-coverage/index.html` in a Web browser.

## Making a release

    $ make distcheck

This will build `pfft-VERSION.tar.gz` and check it.

### Building a Debian package

1. Install build dependencies (one-time step):
   `sudo apt install -y debhelper devscripts`
2. After cloning, run `dpkg-buildpackage -us -uc` in the source directory.
   The package will be left in the parent directory.

## Pull requests

PRs are welcome!  I prefer PRs with one commit that adds tests and a subsequent
commit that adds the code (TDD).  However, that is not required.

Before submitting a PR, please run `make prep`.  This will:

- `make prettyprint` (conform to the coding style)
- `make check` (must pass the tests!)
- `make all build-tests && prove -v` (runs the tests a different way)
- `make html` (make sure there are no valadoc errors)
- `make distcheck` (make sure the tarball will build)

## Notes on compiling Vala sources

- All the .vala files are run through a single pass of `valac`.
  However, the resulting C files are compiled by separate invocations of gcc.
- The valac invocation happens in the _source_ tree.  I think this is because
  the dist tarball includes the generated C files.  Therefore, references
  to the generated .h and .vapi files require `$(srcdir)`.
- Even if you `make clean` or `make distclean`, generated .c files will still
  be left in the tree.  To remove the generated C files,
  `make maintainer-clean`.

## Design decisions

- Decisions about the exact appearance of an item should be made as late
  as possible.  For example, in the `pango-markup` writer (the default),
  headers and footers are set in smaller type by the writer, not the upstream
  code that feeds markup to the writer.

## Other notes

- All files are UTF-8, no BOM.

