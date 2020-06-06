include $(top_srcdir)/rules.mk

AM_VALAFLAGS = \
	-H $(<:.vala=.h) \
	$(MY_VALA_PKGS) \
	$(EOL)

AM_CFLAGS = $(INPUT_CFLAGS) $(RENDER_CFLAGS) $(BASE_CFLAGS)
LIBS = $(INPUT_LIBS) $(RENDER_LIBS) $(BASE_LIBS)

# === Libraries ===========================================================
noinst_LIBRARIES = libpfftcore.a

# === Program =============================================================
bin_PROGRAMS = pfft

pfft_SOURCES = $(MY_pgm_VALA)
pfft_LDADD = libpfftcore.a

libpfftcore_a_SOURCES = doc.vala reader.vala
