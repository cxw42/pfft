SUBDIRS = src t doc

.PHONY: doc test build-tests

# Docs

doc:
	+$(MAKE) -C doc html

# Tests

test: check

build-tests:
	+$(MAKE) -C t build-tests
