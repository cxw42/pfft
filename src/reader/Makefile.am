include $(top_srcdir)/rules.mk

LOCAL_VALA_FLAGS = \
	-H pfft-reader.h --library pfft-reader --vapi pfft-reader.vapi \
	--vapidir $(top_srcdir)/src/core --pkg pfft-core \
	--vapidir $(top_srcdir)/src/logging --pkg pfft-logging \
	$(EOL)

LOCAL_CFLAGS = -I$(top_srcdir)/src/core -I$(top_srcdir)/src/md4c/src

EXTRA_DIST = pfft-reader.h pfft-reader.vapi

noinst_LIBRARIES = libpfft-reader.a
libpfft_reader_a_SOURCES = $(MY_reader_VALA) $(MY_reader_EXTRASOURCES)

# register.c must be compiled after the valac run.
register.$(OBJEXT): libpfft_reader_a_vala.stamp
