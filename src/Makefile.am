include $(top_srcdir)/rules.mk

SUBDIRS = core reader

LOCAL_VALA_FLAGS = $(MY_use_all_valaflags)
LOCAL_CFLAGS = $(MY_use_all_cflags)
LDADD = $(MY_use_all_ldadd)

# === Program =============================================================

bin_PROGRAMS = pfft
pfft_SOURCES = $(MY_pgm_VALA)

# === manpage =============================================================

dist_man1_MANS = pfft.1

EXTRA_DIST = pfft.pod

pfft.1: pfft.pod
	$(AM_V_GEN)pod2man $< $@
