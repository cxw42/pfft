# common rules

# for convenience at the ends of lists
EOL =

# All the Vala files, and the corresponding C files.
MY_pgm_VALA = pfft.vala
MY_core_VALA = doc.vala reader.vala
MY_reader_VALA = reader/markdown-snapd.vala

MY_all_VALA = $(MY_pgm_VALA) $(MY_core_VALA) $(MY_reader_VALA)
MY_VALA_C = $(foreach fn, $(MY_all_VALA), $(fn:.vala=.c))
MY_VALA_H = $(foreach fn, $(MY_all_VALA), $(fn:.vala=.h))

# Vala dependencies
MY_VALA_PKGS = \
	--pkg snapd-glib \
	--pkg pangocairo --pkg pango --pkg cairo \
	--pkg gio-2.0 \
    $(EOL)
