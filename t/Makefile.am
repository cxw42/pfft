include $(top_srcdir)/rules.mk
include $(top_srcdir)/glib-tap.mk

.PHONY: build-tests

build-tests: $(check_PROGRAMS)

# === Flags ===============================================================

LOCAL_VALA_FLAGS = $(MY_use_all_valaflags)
LOCAL_CFLAGS = $(MY_use_all_cflags)
LDADD = $(MY_use_all_ldadd)

# === Programs ============================================================

# So we don't have to list the sources of every test program individually
AM_DEFAULT_SOURCE_EXT = .vala
# But that messes up the linker selection, so:
CCLD = $(CXX)

test_programs = \
	001-sanity-t \
	010-core-util-t \
	020-registry-t \
	050-core-el-t \
	060-core-template-t \
	070-core-writer-t \
	100-logging-t \
	200-md4c-reader-t \
	300-pango-markup-writer-t \
	$(EOL)

dist_test_data = \
	060-bad-version.pfft \
	060-both-headleft.pfft \
	060-core-template.pfft \
	060-empty.pfft \
	060-headfoot-markup.pfft \
	060-no-magic.pfft \
	basic.md \
	complex.md \
	$(EOL)
:
