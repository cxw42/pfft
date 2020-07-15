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

        // TODO make paper size a property

        /** The Cairo context for the document we are writing */
        Cairo.Context cr = null;

        /** The Pango layout for the document we are writing */
        Pango.Layout layout = null;

        /** Used in process_node_into() */
        private Regex re_newline = null;

        // Not a ctor since we create instances through g_object_new() --- see
        // https://gitlab.gnome.org/GNOME/vala/-/issues/650
        construct {
            try {
                re_newline = new Regex("\\R+");
            } catch(RegexError e) {
                assert(false);  // die horribly --- something is very wrong!
            }
        }

        /**
         * Write a document to a file.
         * @param filename  The name of the file to write
         * @param doc       The document to write
         */
        public void write_document(string filename, Doc doc) throws FileError, My.Error
        {
            // Set up the drawing space
            var surf = new Cairo.PdfSurface(filename, 8.5*72, 50*72);   // TODO 50->11 for Letter paper
            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not create surface: " +
                          surf.status().to_string());
            }

            cr = new Cairo.Context(surf);
            layout = Blocks.new_layout_12pt(cr);

            layout.set_width((int)(6.5*72*Pango.SCALE));    // 6.5" wide text column
            // layout.set_markup(markup, -1);

            cr.move_to(1*72, 1*72);     // 1" over, 1" down (respectively) from the UL corner

            // Break the text into individually-rendered blocks
            var blocks = make_blocks(doc);

            // Render
            foreach(var blk in blocks) {
                // TODO handle pagination
                blk.render(cr, 6.5*72*Pango.SCALE, 50*72*Pango.SCALE);  // TODO 50->10 for letter
            }

            cr.show_page();

            // Save the PDF
            surf.finish();
            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not save PDF: " +
                          surf.status().to_string());
            }

        } // write_document

        /** Markup for header levels */
        private string[] header_attributes = {
            "", // level 0
            "size=\"xx-large\" font_weight=\"bold\"",
            "size=\"x-large\" font_weight=\"bold\"",
            "size=\"large\" font_weight=\"bold\"",
            "size=\"large\" font_weight=\"bold\" font_style=\"italic\"",
            "font_weight=\"bold\"",
            "font_weight=\"bold\" font_style=\"italic\"",
        };

        ///////////////////////////////////////////////////////////////////
        // Generate blocks of markup from a Doc.
        // The methods in this section assume cr and layout members are valid

        // === Bulleted/numbered list support =============================

        /** Which bullet types to use as a function of level */
        private IndentType[] indentation_levels_bullets = {
            BLACK_CIRCLE,
            WHITE_CIRCLE,
            BLACK_SQUARE,
            WHITE_SQUARE,
            BLACK_DIAMOND,
            WHITE_DIAMOND,
            BLACK_TRIANGLE,
        };

        /** Which numbering types to use as a function of level */
        private IndentType[] indentation_levels_numbers = {
            ENGLISH_DIGITS,
            LOWERCASE_ALPHA,
            LOWERCASE_ROMAN,
            UPPERCASE_ALPHA,
            UPPERCASE_ROMAN,
        };

        /** Get the type to use for a list item at a particular level */
        private IndentType get_indent_for_level(uint level, bool is_bullet)
        {
            unowned IndentType[] defns = is_bullet ? indentation_levels_bullets :
                indentation_levels_numbers;
            level %= defns.length;  // Cycle through the definitions
            return defns[level];
        }

        /** The rendering state */
        private class State {
            /** Do not change \n to ' ' if true */
            public bool obeylines = false;

            /**
             * Indentation levels.
             *
             * An array used as a stack.  Levels are numbered from 0,
             * so the last used level is levels.length-1.
             */
            public IndentType[] levels = {};

            /**
             * The last number used in each level, or 0 if none.
             */
            public uint[] last_numbers = {};

            public State clone() {
                var retval = new State();
                retval.obeylines = obeylines;
                retval.levels = levels;     // duplicates the array
                retval.last_numbers = last_numbers;
                return retval;
            }
        } // class State

        // === Algorithm ==================================================

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
            var state = new State();

            // Open a Blk that will be filled if the first thing in the Doc is copy
            var first_blk = new Blk(layout);

            // Fill the list
            var last_blk = process_node_into(doc.root, el, (owned)first_blk, retval, state);
            commit(last_blk, retval);

#if 0
            // Tests of alpha
            {
                IndentType ty = LOWERCASE_ALPHA;
                for(int i=1; i<=100; ++i) {
                    printerr("%3d %s\n", i, ty.render(i));
                }
            }
#endif

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
        private /* owned */ Blk process_node_into(GLib.Node<Elem> node, Elem el,
            owned Blk blk, LinkedList<Blk> retval,
            State state_in)
        throws Error
        {
            bool complete = false;  // if true, nothing more to do before committing blk
            string text_markup = Markup.escape_text(el.text);
            string post_children_markup = "";   // markup to be added after the children are processed
            StringBuilder sb = new StringBuilder();

            var state = state_in;

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

            case BLOCK_BULLET_LIST:     // Get the next indentation level
            case BLOCK_NUMBER_LIST:     // Likewise
                complete = true;

                // Copy the state so any changes are localized to this block and
                // any children.
                state = state.clone();

                // Add the indentation level
                var indent = get_indent_for_level(state.levels.length,
                        el.ty == BLOCK_BULLET_LIST);
                state.levels += indent;
                state.last_numbers += 0;
                break;

            case BLOCK_LIST_ITEM:
                commit(blk, retval);
                var lidx = state.levels.length - 1;
                state.last_numbers[lidx]++;

                blk = new BulletBlk(layout, "%s%s".printf(
                            state.levels[lidx].render(state.last_numbers[lidx]),
                            state.levels[lidx].is_bullet() ? "" : "."
                        ),
                        Pango.SCALE * (72 + lidx*36),   // bullet_leftP
                        Pango.SCALE * (72 + lidx*36 + 36) // text_leftP
                );
                sb.append(text_markup);

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

                state = state.clone();
                state.obeylines = true;

                sb.append_printf("<tt>\n%s", text_markup);
                blk.post_markup = "</tt>" + blk.post_markup;
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
                var newblk = process_node_into(child, child.data, (owned)blk,
                        retval, state);
                blk = newblk;
            }

            blk.markup += post_children_markup;

            // Join lines
            if(!state.obeylines) {
                try {
                    blk.markup = re_newline.replace(blk.markup, -1, 0, " ");
                } catch(RegexError e) {
                    // ignore regex errors
                }
            }

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
