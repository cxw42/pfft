include $(top_srcdir)/rules.mk

# All the .vala files are run through valac at once.
LOCAL_VALA_FLAGS = \
	-H pfft-app.h --library pfft-app --vapi pfft-app.vapi \
	--vapidir $(top_srcdir)/src/logging --pkg pfft-logging \
	--vapidir $(top_srcdir)/src/core --pkg pfft-core \
	--vapidir $(top_srcdir)/src/reader --pkg pfft-reader \
	--vapidir $(top_srcdir)/src/writer --pkg pfft-writer \
	$(EOL)

LOCAL_CFLAGS = \
	-I$(top_srcdir)/src/logging \
	-I$(top_srcdir)/src/core \
	-I$(top_srcdir)/src/reader \
	-I$(top_srcdir)/src/writer \
	$(EOL)

EXTRA_DIST = pfft-app.h pfft-app.vapi

noinst_LIBRARIES = libpfft-app.a
libpfft_app_a_SOURCES = $(MY_app_VALA) $(MY_app_EXTRASOURCES)
