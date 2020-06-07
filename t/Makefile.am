include $(top_srcdir)/rules.mk
include $(top_srcdir)/glib-tap.mk

.PHONY: build-tests

build-tests: $(check_PROGRAMS)

# === Flags ===============================================================

LOCAL_VALA_FLAGS = \
	--vapidir ../src/core --pkg pfft-core \
	--vapidir ../src/reader --pkg pfft-reader \
	$(EOL)

LOCAL_CFLAGS = -I../src/core -I../src/reader

LDADD = ../src/core/libpfft-core.a ../src/reader/libpfft-reader.a

# === Programs ============================================================

test_programs = 001-basic.t
dist_test_data = 001-basic.md

001_basic_t_SOURCES = 001-basic.vala
