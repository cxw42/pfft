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
dist_test_scripts = $(MY_script_TESTS)

# Files that tests rely on
dist_test_data = \
	060-bad-values.pfft \
	060-bad-version.pfft \
	060-both-headleft.pfft \
	060-core-template.pfft \
	060-empty-groups.pfft \
	060-empty.pfft \
	060-headfoot-markup.pfft \
	060-no-magic.pfft \
	200-codeblock.md \
	200-html-comment-and-text.md \
	200-html-comment.md \
	200-image-bad.md \
	200-image.md \
	200-special.md \
	200-special-nocmd.md \
	basic.md \
	$(EOL)

# Other sample files
dist_test_data += \
	basic2para.md \
	complex.md \
	elements-of-geology.md \
	image.md \
	README.md \
	$(EOL)
:
