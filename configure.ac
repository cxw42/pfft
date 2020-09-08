dnl === Basic setup =======================================================
AC_INIT([pfft markdown-to-PDF converter], [0.0.3], [], [pfft], [https://github.com/cxw42/pfft])
AC_PREREQ([2.65])
AC_COPYRIGHT([Copyright (C) 2020 Christopher White])
AC_CONFIG_SRCDIR([rules.mk])    dnl make sure the srcdir is correctly specified
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([1.11 foreign subdir-objects])

dnl NOTE: If you add any variables to config.h, make sure to add them
dnl to src/myconfig.vapi as well.
AC_CONFIG_HEADER([config.h])

AC_PROG_CC
AC_PROG_CXX

AM_PROG_VALAC
dnl Known to work with valac 0.40.19

dnl TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
dnl isn't being passed through.
AC_ARG_VAR([USER_VALAFLAGS], [extra options for valac(1)])

AC_PROG_RANLIB

dnl === Code coverage =====================================================

dnl For some reason, the coverage data is referring to src/.../glib-2.0.vapi.
dnl Inject code to strip that from the .info file so genhtml can succeed.
dnl This is all very ugly.  For example, the variables in this section are
dnl hardwired for use in a Makefile, since they assume Makefile syntax
dnl (embedded in sh(1) escaping).

AC_CHECK_PROG([GENHTMLREAL], [genhtml], [genhtml])

GENHTMLHACK="\$(GENHTMLREAL)"
AC_CHECK_PROG([GENHTML], [genhtml], [\$(GENHTMLHACK)])

AX_AM_MACROS_STATIC
AX_CODE_COVERAGE

AM_COND_IF(
    [CODE_COVERAGE_ENABLED],
    [ dnl then
        AC_SUBST([GENHTMLHACK], ['dnl
            perl -n -i -e '"'"'print unless m{\b(?:src|t)/?.*?/glib-2.0.vapi}..m{^end_of_record}'"'"' "$(CODE_COVERAGE_OUTPUT_FILE)" ; dnl
            LANG=C $(GENHTMLREAL) dnl
        '])
    ]
)


dnl === Sanity checks =====================================================

AC_MSG_CHECKING([for local md4c])
AS_IF([test -f "${srcdir}/src/md4c/src/md4c.c" && test -r "${srcdir}/src/md4c/src/md4c.c"],
      [AC_MSG_RESULT([found])],
      [AC_MSG_ERROR([md4c.c not found --- have you run 'git submodule update --init --recursive'?])]
)

dnl === Dependencies ======================================================

PKG_PROG_PKG_CONFIG([0.24])

dnl use fewer variables for terser Makefiles.
PKG_CHECK_MODULES([RENDER],[pangocairo pango cairo])
PKG_CHECK_MODULES([BASE],[
    gee-0.8
    gstreamer-1.0
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

dnl === Hacks =============================================================

# Workaround for automake's prohibiting switches in LDADD.
# Thanks to Gavin Smith,
# https://lists.gnu.org/archive/html/automake/2015-03/msg00004.html
AC_SUBST([wholearchive], [-Wl,--whole-archive])
AC_SUBST([nowholearchive], [-Wl,--no-whole-archive])

dnl === Output ============================================================

AC_CONFIG_FILES([
    Makefile
    doc/Makefile
    src/Makefile
    src/core/Makefile
    src/logging/Makefile
    src/reader/Makefile
    src/writer/Makefile
    t/Makefile
])

AM_SILENT_RULES([yes])
AC_OUTPUT
