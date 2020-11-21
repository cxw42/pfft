# TODO update per
# https://tecnocode.co.uk/2013/12/14/notes-on-vala-and-automake/
include $(top_srcdir)/rules.mk

SUBDIRS = src t doc

.PHONY: doc test build-tests prettyprint prep

# Docs

doc:
	+$(MAKE) -C doc html

# Tests

EXTRA_DIST = tap-driver.sh tap-test

test: check

build-tests:
	+$(MAKE) -C t build-tests

# Misc.

EXTRA_DIST += README.md CONTRIBUTING.md coverage.sh

prettyprint:
	-$(AM_V_GEN)uncrustify -c $(top_srcdir)/.uncrustifyrc --replace \
		$(foreach fn, $(MY_all_VALA), $(top_srcdir)/src/$(fn)) \
		$(foreach fn, $(MY_vala_TESTS), $(top_srcdir)/t/$(fn).vala) \
		$(EOL)

prep:
	@: # TODO check that 'unowned var' does not exist in any vala file
	uncrustify -c $(top_srcdir)/.uncrustifyrc --check \
		$(foreach fn, $(MY_all_VALA), $(top_srcdir)/src/$(fn))
	+$(MAKE) check
	+$(MAKE) html
	+$(MAKE) all build-tests && prove -v
	+$(MAKE) distcheck

# Used by coverage.sh --- remove the existing code-coverage data.
remove-code-coverage-data:
	-rm -rf "$(CODE_COVERAGE_OUTPUT_FILE)" "$(CODE_COVERAGE_OUTPUT_FILE).tmp" "$(CODE_COVERAGE_OUTPUT_DIRECTORY)"
	-find . -name "*.gcda" -delete
