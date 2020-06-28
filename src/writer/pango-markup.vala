// writer/pango-markup.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {

    /**
     * Pango-markup Document writer.
     *
     * Write a document by generating Pango markup for it.
     * Can write the Pango markup or the PDF.
     */
    public class PangoMarkupWriter : Object, Writer {
        /** Metadata for this class */
        [Description(nick = "default", blurb = "Write PDFs using the Pango rendering library")]
        public bool meta {get; default = false; }

        /**
         * Whether to write the Pango markup instead of the PDF.
         *
         * If true, write the Pango markup instead.  Useful for debugging.
         */
        [Description(nick = "write Pango markup", blurb = "If true, write Pango markup instead of the PDF.  For debugging.")]
        public bool write_markup { get; set; default = false; }

        // TODO make paper size a property

        /**
         * Write a document to a file.
         * @param filename  The name of the file to write
         * @param doc       The document to write
         */
        public void write_document(string filename, Doc doc) throws FileError, My.Error
        {
            string markup = make_markup(doc);
            if(write_markup) {
                FileUtils.set_contents(filename, markup);
                return;
            }

            // TODO Make the PDF
            var surf = new Cairo.PdfSurface(filename, 8.5*72, 22*72);   // TODO 22->11 for Letter paper
            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not create surface: " +
                          surf.status().to_string());
            }

            var cr = new Cairo.Context(surf);
            var layout = Pango.cairo_create_layout(cr);

            var font_description = new Pango.FontDescription();
            font_description.set_family("Serif");
            font_description.set_size((int)(12 * Pango.SCALE)); // 12-pt text

            layout.set_width((int)(6.5*72*Pango.SCALE));    // 6.5" wide text column
            layout.set_wrap(Pango.WrapMode.WORD_CHAR);

            layout.set_markup(markup, -1);

            cr.move_to(1*72, 1*72);     // 1" over, 1" down (respectively) from the UL corner
            Pango.cairo_show_layout(cr, layout);
            cr.show_page();

            surf.finish();

            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not save PDF: " +
                          surf.status().to_string());
            }

        }

        /** Markup for header levels */
        private string[] header_attributes = {
            "", // level 0
            "size=\"xx-large\" font_weight=\"bold\"",
            "size=\"x-large\" font_weight=\"bold\"",
            "size=\"large\" font_weight=\"bold\"",
            "size=\"large\"",
            "font_variant=\"smallcaps\" font_weight=\"bold\"",
            "font_variant=\"smallcaps\"",
        };

        /**
         * Generate the markup for a single node, not including its children.
         *
         * Helper for make_markup().
         */
        private void stringify_node(StringBuilder sb, GLib.Node node)
        {
            unowned GLib.Node<Elem> ne = (GLib.Node<Elem>)node;
            unowned Elem el = ne.data;

            StringBuilder child_sb = new StringBuilder();
            child_sb.append(Markup.escape_text(el.text));

            ne.children_foreach(TraverseFlags.ALL,  (child) => {
                stringify_node(child_sb, child);
            });

            switch(el.ty) {
            case ROOT:
                sb.append_printf("%s", child_sb.str);
                break;

            case BLOCK_HEADER:
                sb.append_printf("<span %s>%s</span>\n\n",
                    header_attributes[el.header_level],
                    child_sb.str);
                break;

            case BLOCK_COPY:
                sb.append_printf("%s\n\n", child_sb.str);
                break;

            // TODO manage the blocks - Pango markup won't do them for us
            case BLOCK_QUOTE:
                sb.append_printf("QUOTH THE RAVEN: [%s]\n\n", child_sb.str);
                break;
            case BLOCK_BULLET_LIST:
                sb.append_printf("BULLETS: [%s]\n\n", child_sb.str);
                break;
            case BLOCK_NUMBER_LIST:
                sb.append_printf("NUMBERS: [%s]\n\n", child_sb.str);
                break;
            case BLOCK_LIST_ITEM:
                sb.append_printf("* [%s]\n", child_sb.str);
                break;
            case BLOCK_HR:
                sb.append_printf("-----------[%s]\n\n", child_sb.str);  // TODO
                break;
            case BLOCK_CODE:
                sb.append_printf("<tt>\n%s\n</tt>\n\n", child_sb.str);
                break;

            case SPAN_PLAIN:
                sb.append_printf("%s", child_sb.str);
                break;
            case SPAN_EM:
                sb.append_printf("<span font_style=\"italic\">%s</span>",
                    child_sb.str);
                break;
            case SPAN_STRONG:
                sb.append_printf("<span font_weight=\"bold\">%s</span>",
                    child_sb.str);
                break;
            case SPAN_CODE:
                sb.append_printf("<tt>%s</tt>", child_sb.str);
                break;
            case SPAN_STRIKE:
                sb.append_printf("<s>%s<s>", child_sb.str);
                break;
            case SPAN_UNDERLINE:
                sb.append_printf("<u>%s<u>", child_sb.str);
                break;

            default:
                printerr("I don't know how to handle node type %s for node %p\n",
                    el.ty.to_string(), node);
                break;
            }
        } // stringify_node

        /**
         * Make Pango markup for a document.
         */
        private string make_markup(Doc doc) throws Error
        {
            if(doc.root == null) {
                throw new Error.WRITER("No document to write!");
            }

            var sb = new StringBuilder();
            stringify_node(sb, doc.root);

            print(@"---$(sb.str)---\n");    // debug
            return sb.str;
        }

    }
} // My

// Thanks to the following for information:
// - https://wiki.gnome.org/Projects/Vala/PangoCairoSample
//   by Dov Grobgeld <dov.grobgeld@gmail.com>
// - https://gist.github.com/bert/262331/9dcb6a35460f2eb84571164bf84cbb2a6fc8d367
//   by Bert Timmerman
// - https://developer.gnome.org/pygtk/stable/pango-markup-language.html
// - https://developer.gnome.org/pango/stable/pango-Markup.html
