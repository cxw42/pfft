include $(top_srcdir)/rules.mk

SUBDIRS = src t doc

.PHONY: doc test build-tests

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
	-$(AM_V_GEN)uncrustify -c $(top_srcdir)/.uncrustifyrc --replace $(MY_all_VALA)
