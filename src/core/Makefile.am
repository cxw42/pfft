include $(top_srcdir)/rules.mk

# All the .vala files are run through valac at once.
LOCAL_VALA_FLAGS = -H pfft-core.h --library pfft-core --vapi pfft-core.vapi

EXTRA_DIST = pfft-core.h pfft-core.vapi

noinst_LIBRARIES = libpfft-core.a
libpfft_core_a_SOURCES = $(MY_core_VALA) $(MY_core_EXTRASOURCES)
