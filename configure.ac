dnl === Basic setup =======================================================
AC_INIT([pfft], [0.0.1], [], [pfft], [https://github.com/cxw42/pfft])
AC_PREREQ([2.65])
AC_COPYRIGHT([Copyright (C) 2020 Christopher White])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([1.11 foreign subdir-objects])
AC_CONFIG_HEADER([config.h])

AC_PROG_CC

AM_PROG_VALAC
dnl Known to work with valac 0.40.19

dnl TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
dnl isn't being passed through.
AC_ARG_VAR([USER_VALAFLAGS], [extra options for valac(1)])

AC_PROG_RANLIB

dnl === Dependencies ======================================================

PKG_PROG_PKG_CONFIG([0.24])

dnl use fewer variables for terser Makefiles.
PKG_CHECK_MODULES([INPUT],[snapd-glib >= 1.48])
    dnl v1.48+ for markdown parser
PKG_CHECK_MODULES([RENDER],[pangocairo pango cairo])
PKG_CHECK_MODULES([BASE],[
    gobject-2.0
    gio-2.0
    glib-2.0 >= 2.38
])
    dnl glib version: See g_test_build_filename()

dnl === Tests =============================================================

GLIB_TESTS

dnl === Docs ==============================================================

AC_PATH_PROG([VALADOC], [valadoc], [no])
AM_CONDITIONAL([HAVE_VALADOC], [test "x$VALADOC" '!=' "xno"])

m4_ifdef([GTK_DOC_CHECK], [
GTK_DOC_CHECK([1.14],[--flavour no-tmpl])
],[
AM_CONDITIONAL([ENABLE_GTK_DOC], false)
])

dnl === Output ============================================================

AC_CONFIG_FILES([
    Makefile
    doc/Makefile
    src/Makefile
    src/core/Makefile
    src/reader/Makefile
    t/Makefile
])

AM_SILENT_RULES([yes])
AC_OUTPUT
