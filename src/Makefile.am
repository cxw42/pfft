include $(top_srcdir)/rules.mk

SUBDIRS = core reader

LOCAL_VALA_FLAGS = \
	--vapidir core --pkg pfft-core \
	--vapidir reader --pkg pfft-reader \
	$(EOL)

LOCAL_CFLAGS = -Icore -Ireader

# === Program =============================================================
bin_PROGRAMS = pfft

pfft_SOURCES = $(MY_pgm_VALA)
pfft_LDADD = core/libpfft-core.a reader/libpfft-reader.a
