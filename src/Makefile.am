include $(top_srcdir)/rules.mk

SUBDIRS = logging core reader writer app
EXTRA_DIST =

LOCAL_VALA_FLAGS = $(MY_use_all_valaflags)
LOCAL_CFLAGS = $(MY_use_all_cflags)
LDADD = $(wholearchive) $(MY_use_all_ldadd) $(nowholearchive)

# === Program =============================================================

bin_PROGRAMS = pfft
pfft_SOURCES = nop.cpp $(MY_pgm_VALA) $(MY_pgm_EXTRASOURCES)
# nop.cpp is listed first so the C++ linker will be used.

# === manpage =============================================================

dist_man1_MANS = pfft.1

EXTRA_DIST += pfft.pod

pfft.1: pfft.pod Makefile.am
	$(AM_V_GEN)pod2man $< $@ \
		-s 1 \
		--center='User Commands' \
		-r 'v@PACKAGE_VERSION@' \
		$(EOL)
