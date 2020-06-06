include $(top_srcdir)/rules.mk

AM_VALAFLAGS = \
	-H $(<:.vala=.h) \
	--pkg pangocairo --pkg pango --pkg cairo --pkg gio-2.0 \
	$(EOL)

AM_CFLAGS = $(PANGO_CFLAGS) $(GLIB_CFLAGS)
LIBS = $(PANGO_LIBS) $(GLIB_LIBS)

bin_PROGRAMS = pfft

pfft_SOURCES = $(MY_VALA_VALA)
