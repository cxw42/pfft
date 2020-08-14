include $(top_srcdir)/rules.mk

# All the .vala files are run through valac at once.
LOCAL_VALA_FLAGS = -H pfft-logging.h --library pfft-logging --vapi pfft-logging.vapi

EXTRA_DIST = pfft-logging.h pfft-logging.vapi

noinst_LIBRARIES = libpfft-logging.a
libpfft_logging_a_SOURCES = $(MY_logging_VALA) $(MY_logging_EXTRASOURCES)
