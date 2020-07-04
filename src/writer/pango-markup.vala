// writer/pango-markup.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Gee;
using My.Blocks;

namespace My {

    /**
     * Pango-markup document writer.
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

        /** The Cairo context for the document we are writing */
        Cairo.Context cr = null;

        /** The Pango layout for the document we are writing */
        Pango.Layout layout = null;

        /**
         * Write a document to a file.
         * @param filename  The name of the file to write
         * @param doc       The document to write
         */
        public void write_document(string filename, Doc doc) throws FileError, My.Error
        {
            //string markup = make_markup(doc);
            if(write_markup) {
                //emit(filename, markup);
                throw new Error.WRITER("Not implemented");
            }

            // TODO Make the PDF
            var surf = new Cairo.PdfSurface(filename, 8.5*72, 50*72);   // TODO 50->11 for Letter paper
            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not create surface: " +
                          surf.status().to_string());
            }

            cr = new Cairo.Context(surf);
            layout = Blocks.new_layout_12pt(cr);

            layout.set_width((int)(6.5*72*Pango.SCALE));    // 6.5" wide text column
            //layout.set_markup(markup, -1);

            cr.move_to(1*72, 1*72);     // 1" over, 1" down (respectively) from the UL corner
            //Pango.cairo_show_layout(cr, layout);

            var blocks = make_blocks(doc);
            foreach(var blk in blocks) {
                // TODO handle pagination
                blk.render(cr, 6.5*72*Pango.SCALE, 50*72*Pango.SCALE);  // TODO 50->10 for letter
            }

            cr.show_page();

            surf.finish();

            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not save PDF: " +
                          surf.status().to_string());
            }

        } //write_document

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

        ///////////////////////////////////////////////////////////////////
        // Generate blocks of markup from a Doc
        // The functions in this section assume cr and layout members are valid

        /**
         * Make Pango markup blocks for a document
         */
        private LinkedList<Blk> make_blocks(Doc doc) throws Error
        {
            if(doc.root == null) {
                throw new Error.WRITER("No document to write!");
            }

            var el = doc.root.data;
            if(el == null || el.ty != ROOT) {
                throw new Error.WRITER(
                          "Document doesn't start with a ROOT node (%s)".printf(doc.root.data.ty.to_string()));
            }

            var retval = new LinkedList<Blk>();

            // Open a Blk that will be filled if the first thing in the Doc is copy
            var first_blk = new Blk(layout);

            // Fill the list
            var last_blk = process_node_into(doc.root, el, (owned)first_blk, retval);
            commit(last_blk, retval);

            return retval;
        } // make_blocks()

        /**
         * Add a block to the list of blocks to be rendered.
         * @param   blk     The block to add
         * @param   retval  The list to add blk to
         *
         * If blk is not a duplicate of  the last-added block, this function
         * adds blk to retval.
         *
         * This is in a separate function in case I later need to add more
         * per-blk commit processing.
         */
        private void commit(owned Blk blk, LinkedList<Blk> retval)
        {
            if(!retval.is_empty && retval.last() == blk) return;
            // XXX DEBUG
            print("commit: adding blk with markup <%s> and post-markup <%s>\n",
                  blk.markup, blk.post_markup);
            retval.add(blk);
        }

        /**
         * Make Pango markup block(s) for a node
         * @param node      The current node
         * @param el        The element (convenience accessor for node.data)
         * @param blk       The current block being built
         * @param retval    The list to which a block should be appended
         *                  when complete.
         * @return The block in progress
         */
        private /* owned */ Blk process_node_into(GLib.Node<Elem> node, Elem el, owned Blk blk, LinkedList<Blk> retval)
        throws Error
        {
            bool complete = false;  // if true, nothing more to do before committing blk
            string text_markup = Markup.escape_text(el.text);
            string post_children_markup = "";   // markup to be added after the children are processed
            StringBuilder sb = new StringBuilder();

            // DEBUG
            print("process_node_into: %s%s %p = '%s'\n",
                  string.nfill(node.depth()*4, ' '), el.ty.to_string(), node,
                  text_markup);

            switch(el.ty) {
            case ROOT:
                // Nothing else to do
                break;

            // --- divs -----------------------------------------
            case BLOCK_HEADER:
                commit(blk, retval);
                blk = new Blk(layout);
                sb.append_printf("<span %s>%s",
                    header_attributes[el.header_level],
                    text_markup);
                blk.post_markup = "</span>";
                complete = true;
                break;

            case BLOCK_COPY:
                blk.append_paragraph_markup(text_markup);
                // Do not create a new blk here since there may be other
                // nodes that have yet to contribute to blk.
                complete = true;
                break;

            case BLOCK_QUOTE:
                commit(blk, retval);
                blk = new Blk(layout);
                sb.append_printf("QUOTH THE RAVEN: [%s", text_markup);
                blk.post_markup = "]" + blk.post_markup;
                complete = true;
                break;
            case BLOCK_BULLET_LIST:
                commit(blk, retval);
                blk = new Blk(layout);
                sb.append_printf("BULLETS: [%s", text_markup);
                blk.post_markup = "]" + blk.post_markup;
                complete = true;
                break;
            case BLOCK_NUMBER_LIST:
                commit(blk, retval);
                blk = new Blk(layout);
                sb.append_printf("NUMBERS: [%s", text_markup);
                blk.post_markup = "]" + blk.post_markup;
                complete = true;
                break;
            case BLOCK_LIST_ITEM:
                commit(blk, retval);
                blk = new Blk(layout);
                sb.append_printf("* [%s", text_markup);
                blk.post_markup = "]" + blk.post_markup;
                complete = true;
                break;
            case BLOCK_HR:
                commit(blk, retval);
                blk = new Blk(layout);
                sb.append_printf("-----------[%s", text_markup);   // TODO
                blk.post_markup = "]" + blk.post_markup;
                complete = true;
                break;
            case BLOCK_CODE:
                commit(blk, retval);
                blk = new Blk(layout);
                sb.append_printf("<tt>\n%s", text_markup);
                blk.post_markup = "\n</tt>\n" + blk.post_markup;
                complete = true;
                break;

            // --- spans ----------------------------------------
            case SPAN_PLAIN:
                sb.append(text_markup);
                break;
            case SPAN_EM:
                sb.append_printf("<span font_style=\"italic\">%s",
                    text_markup);
                post_children_markup = "</span>";
                break;
            case SPAN_STRONG:
                sb.append_printf("<span font_weight=\"bold\">%s",
                    text_markup);
                post_children_markup = "</span>";
                break;
            case SPAN_CODE:
                sb.append_printf("<tt>%s", text_markup);
                post_children_markup = "</tt>";
                break;
            case SPAN_STRIKE:
                sb.append_printf("<s>%s", text_markup);
                post_children_markup = "</s>";
                break;
            case SPAN_UNDERLINE:
                sb.append_printf("<u>%s", text_markup);
                post_children_markup = "</u>";
                break;

            // --------------------------------------------------
            default:
                warning("Unknown div type %s", el.ty.to_string());
                break;
            }

            blk.append_paragraph_markup(sb.str);

            // process children
            for(uint i = 0; i < node.n_children(); ++i) {
                unowned GLib.Node<Elem> child = node.nth_child(i);
                var newblk = process_node_into(child, child.data, (owned)blk, retval);
                blk = newblk;
            }

            blk.markup += post_children_markup;

            if(complete) {
                commit(blk, retval);
                blk = new Blk(layout);
            }

            return (owned)blk;
        } // process_div_into

    } // class PangoMarkupWriter
} // My

// Thanks to the following for information:
// - https://wiki.gnome.org/Projects/Vala/PangoCairoSample
//   by Dov Grobgeld <dov.grobgeld@gmail.com>
// - https://gist.github.com/bert/262331/9dcb6a35460f2eb84571164bf84cbb2a6fc8d367
//   by Bert Timmerman
// - https://developer.gnome.org/pygtk/stable/pango-markup-language.html
// - https://developer.gnome.org/pango/stable/pango-Markup.html
