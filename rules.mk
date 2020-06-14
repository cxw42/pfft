# common rules

# for convenience at the ends of lists
EOL =

# All the Vala files, and the corresponding C files.  One variable per
# directory under src/
MY_pgm_VALA = pfft.vala
MY_core_VALA = el.vala reader.vala util.vala writer.vala
MY_reader_VALA = markdown-snapd.vala
MY_writer_VALA = pango-markup.vala
MY_subdirs = core reader writer

MY_all_VALA = \
	$(MY_pgm_VALA) \
	$(foreach dir, $(MY_subdirs), \
		$(foreach fn, $(MY_$(dir)_VALA), $(dir)/$(fn)) \
	) \
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
# TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
# isn't being passed through.
AM_VALAFLAGS = \
	$(LOCAL_VALA_FLAGS) \
	$(MY_VALA_PKGS) \
	$(USER_VALAFLAGS) \
	$(EOL)

# not this => -H $(<:.vala=.h)
# because all the .vala files are run through a single invocation of valac.

# C settings, which are the same throughout.  LOCAL_CFLAGS is filled in
# by each Makefile.am.
AM_CFLAGS = $(LOCAL_CFLAGS) $(INPUT_CFLAGS) $(RENDER_CFLAGS) $(BASE_CFLAGS)
LIBS = $(INPUT_LIBS) $(RENDER_LIBS) $(BASE_LIBS)

# Flags used by both the program and the tests --- anything that links
# against all the libraries
MY_use_all_valaflags = \
	$(foreach dir, $(MY_subdirs), \
		--vapidir $(top_srcdir)/src/$(dir) --pkg pfft-$(dir) \
	) \
	$(EOL)

MY_use_all_cflags = \
	$(foreach dir, $(MY_subdirs), \
		-I$(top_srcdir)/src/$(dir) \
	) \
	$(EOL)

MY_use_all_ldadd = \
	$(foreach dir, $(MY_subdirs), \
		$(top_builddir)/src/$(dir)/libpfft-$(dir).a \
	) \
	$(EOL)
