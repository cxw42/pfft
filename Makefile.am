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

prettyprint:
	-$(AM_V_GEN)uncrustify -c $(top_srcdir)/.uncrustifyrc --replace \
		$(foreach fn, $(MY_all_VALA), $(top_srcdir)/src/$(fn))

prep:
	uncrustify -c $(top_srcdir)/.uncrustifyrc --check \
		$(foreach fn, $(MY_all_VALA), $(top_srcdir)/src/$(fn))
	+$(MAKE) check
	+$(MAKE) all build-tests && prove -v
	+$(MAKE) distcheck
