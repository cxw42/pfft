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
            var surf = new Cairo.PdfSurface(filename, 8.5*72, 11*72);   // Letter paper
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

            layout.set_text(markup, -1);

            cr.move_to(1*72, 2*72);     // 1" over, 2" down from the UL corner
            Pango.cairo_show_layout(cr, layout);
            cr.show_page();

            surf.finish();

            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not save PDF: " +
                                       surf.status().to_string());
            }

        }

        /**
         * Make Pango markup for a document.
         */
        private string make_markup(Doc doc)
        {
            return "Not yet implemented!  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
        }

    }
} // My

// Thanks to the following for information:
// - https://wiki.gnome.org/Projects/Vala/PangoCairoSample
//   by Dov Grobgeld <dov.grobgeld@gmail.com>
// - https://gist.github.com/bert/262331/9dcb6a35460f2eb84571164bf84cbb2a6fc8d367
//   by Bert Timmerman
