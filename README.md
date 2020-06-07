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

    $ sudo apt install -y libpango1.0-dev   # Or equivalent on non-Ubuntu
    $ sudo apt install -y --no-install-recommends libsnapd-glib1

(Note the `--no-install-recommends` --- you don't need snapd installed.
I am just using the Markdown parser in snapd-glib since it's there.)

    $ tar xvf pfft-VERSION.tar.gz
    $ cd pfft-VERSION
    $ ./configure && make -j4 && sudo make install

For the HTML documentation, run `make html`, then open
`doc/valadoc/pfft/index.htm`.

## Hacking on Pfft

### Building from Git

Tested on Lubuntu Eoan.

Install the latest stable [valac]:

    $ sudo apt install -y build-essential valac valadoc valac-0.44-vapi graphviz-dev help2man
    $ git clone https://gitlab.gnome.org/GNOME/vala.git
    $ cd vala
    $ git checkout 0.48.6   # or whatever the latest stable is
    $ ./autogen.sh && make -j4 && sudo make install

Install dependencies for pfft:

    $ sudo apt install -y autotools-dev libpango1.0-dev libsnapd-glib-dev
    $ sudo apt install -y --no-install-recommends libsnapd-glib1

Build:

    $ ./bootstrap
    $ ./configure && make -j4

Note: `libpango1.0-dev` pulls in Pango, Cairo, and pangocairo.

### Testing

`make test` or `make check` at the top level.

In GLib 2.62+, the default output format is TAP.  Therefore, you can do
`make build-tests && prove`.

### Notes on compiling Vala sources

- All the .vala files are run through a single pass of `valac`.
  However, the resulting C files are compiled by separate invocations of gcc.
- Even if you `make clean` or `make distclean`, generated .c files will still
  be left in the tree.  To remove the generated C files,
  `make maintainer-clean`.

## Thanks

- <https://github.com/stefantalpalaru/vala-skeleton-autotools>
- <https://github.com/D3Engineering/d3-jetson-bsp>

[valac]: https://wiki.gnome.org/Projects/Vala
