// writer/pango-blocks.vala
//
// Blocks of content
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My { namespace Blocks {

    /** Results of a Blk.render() call */
    public enum RenderResult {
        ERROR,
        /** The whole block was rendered */
        COMPLETE,
        /** There is more to render, e.g., on the next page */
        PARTIAL,
    }

    /**
     * Block of content to be written.
     *
     * Blk itself knows how to render body paragraphs.  It also serves as the
     * base class for more specialized blocks.
     */
    public class Blk : Object {
        /**
         * The block's text, in Pango markup.
         *
         * This definition is here so child classes don't have to repeat it.
         * However, a child class is not obliged to use this.
         *
         * NOTE: Pango obeys `\n`s in the markup, so the caller must remove
         * them for automatically-wrapped text.
         */
        public string markup { get; set; }

        /**
         * Render a markup block with no decorations.
         *
         * This is a helper for child classes.
         */
        protected static RenderResult render_simple(Cairo.Context cr,
            double rightP, double bottomP, string final_markup)
        {

            double xC, yC;  // Cairo current points (Cairo.PdfSurface units are pts)
            cr.get_current_point(out xC, out yC);

            // Out of range
            if(xC*Pango.SCALE >= rightP || yC*Pango.SCALE >= bottomP) {
                return RenderResult.ERROR;
            }

            var layout = Pango.cairo_create_layout(cr);

            var font_description = new Pango.FontDescription();
            font_description.set_family("Serif");
            font_description.set_size((int)(12 * Pango.SCALE)); // 12-pt text

            layout.set_width((int)(rightP - xC*Pango.SCALE));
            layout.set_wrap(Pango.WrapMode.WORD_CHAR);

            layout.set_markup(final_markup, -1);

            // TODO check metrics and see if we are at risk of running
            // off the page

            Pango.cairo_show_layout(cr, layout);

            return RenderResult.COMPLETE;
        } // render_simple()

        /**
         * Render this block at the current position on the context.
         * @param cr        The context to render into
         * @param rightP    The right limit, in Pango units
         * @param bottomP   The bottom limit, in Pango units
         *
         * The caller must set the current position to the left margin
         * of this block before calling this method.
         *
         * rightP and bottomP are not hard limits, but say where the margins
         * are:
         * * Text rendered to the right of rightP is in the right margin.
         * * Text rendered below bottomP is in the bottom margin.
         *
         */
        public virtual RenderResult render(Cairo.Context cr,
            double rightP, double bottomP)
        {
            return render_simple(cr, rightP, bottomP, markup);
        }

    } // class Blk

    /** Header */
    public class Header : Blk
    {
        /** Header level (1..6) */
        public int level { get; set; }

        public Header(int level, string text = "")
        {
            this.level = level;
            if(text != "") {
                this.markup = Markup.escape_text(text);
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
         * Render the header.
         *
         * Reads the text of the header from its markup property.
         */
        public override RenderResult render(Cairo.Context cr,
            double rightP, double bottomP)
        {
            string final_markup = "<span %s>%s</span>".printf(
                header_attributes[level], markup
            );

            return render_simple(cr, rightP, bottomP, final_markup);
        }

    } // class Header

#if 0
    /**
     * A factory class that creates blocks to hold paragraph-level elements.
     */
    class Factory : Blk
    {
        protected override Blk accept_root(Elem el) {
            return this;
        }

        protected override Blk accept_block_header(Elem el) {
            // return new Header(el.
            // var blk = new Header(
            return unhandled_elem(el);
        }
    } // class Factory
#endif

}}
