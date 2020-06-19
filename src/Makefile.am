include $(top_srcdir)/rules.mk

SUBDIRS = core reader writer
EXTRA_DIST =
DISTCLEANFILES =

LOCAL_VALA_FLAGS = $(MY_use_all_valaflags)
LOCAL_CFLAGS = $(MY_use_all_cflags)
LDADD = $(wholearchive) $(MY_use_all_ldadd) $(nowholearchive)

# === myconfig package ====================================================
# Gives access to config.h

myconfig.vapi: $(top_srcdir)/config.h
	$(srcdir)/gen-myconfig.pl $< > $@

EXTRA_DIST += myconfig.vapi gen-myconfig.pl
DISTCLEANFILES += myconfig.vapi

# === Program =============================================================

bin_PROGRAMS = pfft
pfft_SOURCES = nop.cpp $(MY_pgm_VALA) myconfig.vapi
# nop.cpp is listed first so the C++ linker will be used.

# === manpage =============================================================

dist_man1_MANS = pfft.1

EXTRA_DIST += pfft.pod

pfft.1: pfft.pod
	$(AM_V_GEN)pod2man $< $@
