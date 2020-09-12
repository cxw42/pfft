include $(top_srcdir)/rules.mk

hdrstamp = tweaked-header.stamp

# All the .vala files are run through valac at once.
LOCAL_VALA_FLAGS = -H pfft-logging.h --library pfft-logging --vapi pfft-logging.vapi

EXTRA_DIST = pfft-logging.h pfft-logging.vapi

noinst_LIBRARIES = libpfft-logging.a
libpfft_logging_a_SOURCES = $(MY_logging_VALA) $(MY_logging_EXTRASOURCES) \
			    $(hdrstamp)

# Run after valac to create logging.o by hand.  logging.c has nothing we need,
# and on older Vala versions includes function prototypes of the GST_DEBUG
# macros!  Therefore, create an empty logging.o from an empty C file so that
# the link command will work.
logging.$(OBJEXT): $(srcdir)/libpfft_logging_a_vala.stamp $(hdrstamp)
	cat /dev/null > dummy.c
	$(CC) -c -o $@ dummy.c

CLEANFILES = dummy.c

# Remove GST_* function prototypes from pfft-logging.h
$(hdrstamp): $(srcdir)/libpfft_logging_a_vala.stamp
	perl -i -e 'local $$/; $$_ = <>; s/^void (?:GST|my_assert).*?;//gms; s/^gboolean my_log_lenabled.*?;//gms; print' $(srcdir)/pfft-logging.h
	touch $@

MAINTAINERCLEANFILES = $(hdrstamp)
