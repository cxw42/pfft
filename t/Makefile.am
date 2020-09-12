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

test_programs = $(MY_vala_TESTS)

dist_test_data = \
	060-bad-values.pfft \
	060-bad-version.pfft \
	060-both-headleft.pfft \
	060-core-template.pfft \
	060-empty-groups.pfft \
	060-empty.pfft \
	060-headfoot-markup.pfft \
	060-no-magic.pfft \
	basic.md \
	complex.md \
	$(EOL)
:
