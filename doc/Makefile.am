include $(top_srcdir)/rules.mk

.PHONY: valadoc clean-valadoc

all-local: valadoc

clean-local: clean-valadoc

if HAVE_VALADOC

valadoc:
	valadoc -o valadoc -b $(top_srcdir)/src --verbose --force \
		--package-name='@PACKAGE_NAME@' \
		--package-version='@PACKAGE_VERSION@' \
		$(foreach fn, $(MY_VALA_VALA), $(top_srcdir)/src/$(fn)) \
		--doclet=html \
		$(EOL)

# for gtk-doc, add to the valadoc invocation:
#		--doclet=gtkdoc
#		$(foreach fn, $(MY_VALA_C) $(MY_VALA_H),
#			-X $(top_srcdir)/src/$(fn))
# and add gtk-doc-tools to the list of required devel packages

clean-valadoc:
	-rm -rf valadoc

else

valadoc:
	echo "Please check your valadoc installation and try again"

clean-valadoc:
	@: #Nothing to do

endif
