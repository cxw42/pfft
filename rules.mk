# common rules

# for convenience at the ends of lists
EOL =

# All the Vala files, and the corresponding C files.
MY_pgm_VALA = pfft.vala
MY_core_VALA = doc.vala reader.vala markdown-element.vala
MY_reader_VALA = markdown-snapd.vala

MY_all_VALA = \
	$(MY_pgm_VALA) \
	$(foreach fn, $(MY_core_VALA), core/$(fn)) \
	$(foreach fn, $(MY_reader_VALA), reader/$(fn)) \
	$(EOL)

MY_VALA_C = $(foreach fn, $(MY_all_VALA), $(fn:.vala=.c))
MY_VALA_H = $(foreach fn, $(MY_all_VALA), $(fn:.vala=.h))

# Vala dependencies
MY_VALA_PKGS = \
	--pkg snapd-glib \
	--pkg pangocairo --pkg pango --pkg cairo \
	--pkg gio-2.0 \
	$(EOL)

# Vala settings.  LOCAL_VALA_FLAGS is filled in by each Makefile.am with
# any other valac options that Makefile.am needs.
AM_VALAFLAGS = \
	$(LOCAL_VALA_FLAGS) \
	$(MY_VALA_PKGS) \
	$(EOL)

# not this => -H $(<:.vala=.h)
# because all the .vala files are run through a single invocation of valac.

# C settings, which are the same throughout.  LOCAL_CFLAGS is filled in
# by each Makefile.am.
AM_CFLAGS = $(LOCAL_CFLAGS) $(INPUT_CFLAGS) $(RENDER_CFLAGS) $(BASE_CFLAGS)
LIBS = $(INPUT_LIBS) $(RENDER_LIBS) $(BASE_LIBS)
