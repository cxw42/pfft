include $(top_srcdir)/rules.mk

# All the .vala files are run through valac at once.
LOCAL_VALA_FLAGS = -H pfft-logging.h --library pfft-logging --vapi pfft-logging.vapi

EXTRA_DIST = pfft-logging.h pfft-logging.vapi

noinst_LIBRARIES = libpfft-logging.a
libpfft_logging_a_SOURCES = $(MY_logging_VALA) $(MY_logging_EXTRASOURCES)

# Run after valac to create logging.o by hand.  logging.c has nothing we need,
# and on older Vala versions includes function prototypes of the GST_DEBUG
# macros!  Therefore, create an empty logging.o from an empty C file so that
# the link command will work.
logging.$(OBJEXT): $(srcdir)/libpfft_logging_a_vala.stamp
	cat /dev/null > dummy.c
	$(CC) -c -o $@ dummy.c

CLEANFILES = dummy.c
