# PDF From Formatted Text: markdown to PDF with fewer dependencies

[![Build Status](https://travis-ci.org/cxw42/pfft.svg?branch=master)](https://travis-ci.org/cxw42/pfft)
[![codecov](https://codecov.io/gh/cxw42/pfft/branch/master/graph/badge.svg)](https://codecov.io/gh/cxw42/pfft)

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

## Contributing to Pfft's development

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Thanks

- <https://github.com/stefantalpalaru/vala-skeleton-autotools>
- <https://github.com/D3Engineering/d3-jetson-bsp>

## Legal

Most of pfft is BSD-3-clause (see file [`LICENSE`](LICENSE)).  The files in `src/logging`
are LGPL 2.1+ (see file [`LGPL-2.1`](LGPL-2.1)).
