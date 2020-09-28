# common rules

# for convenience at the ends of lists
EOL =

# All the Vala files, and the corresponding C files.  One variable per
# directory under src/ .  Each variable refers to files in the
# corresponding subdirectory.  The subdirectories are added by the variables
# that use these.

# src/
MY_pgm_VALA = main.vala

# src/app
MY_app_VALA = pfft.vala myconfig.vapi
# myconfig.vapi is under source control, so make sure to update it manually
# if you add symbols to config.h.
MY_app_EXTRASOURCES = pfft-shim.c

# src/core
MY_core_VALA = el.vala reader.vala registry.vala template.vala units.vala util.vala writer.vala
MY_core_EXTRASOURCES = registry-impl.cpp

# src/logging
MY_logging_VALA = logging.vala
MY_logging_EXTRASOURCES = logging-c.h logging-c.c

# src/reader
MY_reader_VALA = md4c-reader.vala \
		 md4c.vapi \
		 $(EOL)
MY_reader_EXTRASOURCES = register.c \
			 $(top_srcdir)/src/md4c/src/md4c.c \
			 $(top_srcdir)/src/md4c/src/md4c.h \
			 md4c-shim.c md4c-shim.h \
			 reader-shim.c reader-shim.h \
			 $(EOL)

# src/writer
MY_writer_VALA = pango-markup.vala pango-blocks.vala \
		 dumper.vala
MY_writer_EXTRASOURCES = register.c

# subdirs.  Listed in the order they should appear on link lines.
MY_subdirs = app reader writer core logging

MY_all_VALA = \
	$(MY_pgm_VALA) \
	$(foreach dir, $(MY_subdirs), \
		$(foreach fn, $(MY_$(dir)_VALA), $(dir)/$(fn)) \
	) \
	$(EOL)

MY_VALA_C = $(foreach fn, $(MY_all_VALA), $(fn:.vala=.c))
MY_VALA_H = $(foreach fn, $(MY_all_VALA), $(fn:.vala=.h))

# Tests.  Listed here so they can be pretty-printed.
MY_vala_TESTS = \
	001-sanity-t \
	010-core-util-t \
	020-registry-t \
	021-registry-classmap-t \
	050-core-el-t \
	055-core-units-t \
	060-core-template-t \
	070-core-writer-t \
	100-logging-t \
	200-md4c-reader-t \
	300-pango-markup-writer-t \
	305-pango-markup-utils-t \
	$(EOL)

# Vala dependencies
MY_VALA_PKGS = \
	--pkg pangocairo --pkg pango --pkg cairo \
	--pkg gee-0.8 \
	--pkg gstreamer-1.0 \
	--pkg gobject-2.0 \
	--pkg gio-2.0 \
	$(EOL)

# Vala settings.
# - LOCAL_VALA_FLAGS is filled in by each Makefile.am with any other valac
#   options that Makefile.am needs.
# - Always use the C++ compiler for the generated code, since the
#   registry relies on it.
# - TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
#   isn't being passed through.
AM_VALAFLAGS = \
	$(LOCAL_VALA_FLAGS) \
	--cc=$(CXX) \
	$(MY_VALA_PKGS) \
	$(USER_VALAFLAGS) \
	$(EOL)

# not this => -H $(<:.vala=.h)
# because all the .vala files are run through a single invocation of valac.

# C settings, which are the same throughout.  LOCAL_CFLAGS is filled in
# by each Makefile.am.
AM_CFLAGS = $(LOCAL_CFLAGS) $(INPUT_CFLAGS) $(RENDER_CFLAGS) $(BASE_CFLAGS) $(CODE_COVERAGE_CFLAGS)
AM_CXXFLAGS = $(AM_CFLAGS) $(CODE_COVERAGE_CXXFLAGS)
AM_CPPFLAGS = $(CODE_COVERAGE_CPPFLAGS)
LIBS = $(INPUT_LIBS) $(RENDER_LIBS) $(BASE_LIBS) $(CODE_COVERAGE_LIBS)

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

# For code coverage, per
# https://www.gnu.org/software/autoconf-archive/ax_code_coverage.html
clean-local: code-coverage-clean
distclean-local: code-coverage-dist-clean

CODE_COVERAGE_OUTPUT_FILE = $(PACKAGE_TARNAME)-coverage.info
CODE_COVERAGE_OUTPUT_DIRECTORY = $(PACKAGE_TARNAME)-coverage

include $(top_srcdir)/aminclude_static.am
