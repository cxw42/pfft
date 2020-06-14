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
    public class PangoMarkupWriter: Object, Writer {
        /**
         * Whether to write the PDF.
         *
         * If false, write the Pango markup instead.  Useful for debugging.
         */
        public bool write_pdf { get; set; default = true; }

        /**
         * Write a document to a file.
         * @param filename  The name of the file to write
         * @param doc       The document to write
         */
        public void write_document(string filename, Doc doc) throws FileError
        {
            string markup = make_markup(doc);
            if(!write_pdf) {
                FileUtils.set_contents(filename, markup);
                return;
            }

            // TODO Make the PDF
            error("PDF writing not yet implemented");
        }

        /**
         * Make Pango markup for a document.
         */
        private string make_markup(Doc doc)
        {
            return "Not yet implemented!";
        }

    }
} // My
