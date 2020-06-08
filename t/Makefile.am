include $(top_srcdir)/rules.mk
include $(top_srcdir)/glib-tap.mk

.PHONY: build-tests

build-tests: $(check_PROGRAMS)

# === Flags ===============================================================

LOCAL_VALA_FLAGS = $(MY_use_all_valaflags)
LOCAL_CFLAGS = $(MY_use_all_cflags)
LDADD = $(MY_use_all_ldadd)

# === Programs ============================================================

test_programs = 001-basic.t
dist_test_data = 001-basic.md

001_basic_t_SOURCES = 001-basic.vala
