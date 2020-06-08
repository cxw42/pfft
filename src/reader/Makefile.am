include $(top_srcdir)/rules.mk

LOCAL_VALA_FLAGS = \
	-H pfft-reader.h --library pfft-reader --vapi pfft-reader.vapi \
	--vapidir $(top_srcdir)/src/core --pkg pfft-core \
	$(EOL)

LOCAL_CFLAGS = -I$(top_srcdir)/src/core

EXTRA_DIST = pfft-reader.h pfft-reader.vapi

noinst_LIBRARIES = libpfft-reader.a
libpfft_reader_a_SOURCES = $(MY_reader_VALA)
