include $(top_srcdir)/rules.mk

LOCAL_VALA_FLAGS = \
	-H pfft-writer.h --library pfft-writer --vapi pfft-writer.vapi \
	--vapidir $(top_srcdir)/src/core --pkg pfft-core \
	--vapidir $(top_srcdir)/src/logging --pkg pfft-logging \
	--pkg gee-0.8 \
	$(EOL)

LOCAL_CFLAGS = -I$(top_srcdir)/src/core -I$(top_srcdir)/src/logging

EXTRA_DIST = pfft-writer.h pfft-writer.vapi

noinst_LIBRARIES = libpfft-writer.a
libpfft_writer_a_SOURCES = $(MY_writer_VALA) $(MY_writer_EXTRASOURCES)

# register.c must be compiled after the valac run.
register.$(OBJEXT): libpfft_writer_a_vala.stamp
