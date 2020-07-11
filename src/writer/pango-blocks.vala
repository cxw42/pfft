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
     * Create a layout with 12-pt text.
     *
     * Here for convenience.
     *
     * @param cr The Cairo context with which this layout will be used
     */
    public static Pango.Layout new_layout_12pt(Cairo.Context cr)
    {
        var layout = Pango.cairo_create_layout(cr);

        var font_description = new Pango.FontDescription();
        font_description.set_family("Serif");
        font_description.set_size((int)(12 * Pango.SCALE)); // 12-pt text
        layout.set_wrap(Pango.WrapMode.WORD_CHAR);

        return layout;
    } // new_layout_12pt()

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
        public string markup { get; set; default = ""; }

        /**
         * Additional markup to be added to the end of the block before rendering.
         * A child class is not obliged to use this.
         */
        public string post_markup { get; set; default = ""; }

        /**
         * A layout instance to use.
         *
         * This is so the font and wrap can be consistent between blocks.
         */
        protected Pango.Layout layout;

        /**
         * Helper to add a paragraph to markup
         *
         * No-op if new_markup is empty.  Otherwise. adds a newline before
         * new_markup if there is already any content in markup.
         */
        public void append_paragraph_markup(string new_markup)
        {
            markup += new_markup;
        }

        /**
         * Render a markup block with no decorations.
         *
         * This is a helper for child classes.  If final_markup is empty,
         * this is a no-op.
         */
        protected static RenderResult render_simple(Cairo.Context cr,
            Pango.Layout layout,
            double rightP, double bottomP, string final_markup)
        {
            double xC, yC;  // Cairo current points (Cairo.PdfSurface units are pts)

            if(final_markup == "") {
                return RenderResult.COMPLETE;
            }

            cr.get_current_point(out xC, out yC);

            // Out of range
            if(xC*Pango.SCALE >= rightP || yC*Pango.SCALE >= bottomP) {
                return RenderResult.ERROR;
            }

            layout.set_width((int)(rightP - xC*Pango.SCALE));
            layout.set_markup(final_markup, -1);

            // TODO check metrics and see if we are at risk of running
            // off the page

            Pango.cairo_show_layout(cr, layout);

            // Move down the page
            Pango.Rectangle inkP, logicalP;
            layout.get_extents(out inkP, out logicalP);

            // XXX DEBUG
            print("ink: %dx%d@(%d,%d)\n", inkP.width/Pango.SCALE,
                  inkP.height/Pango.SCALE, inkP.x/Pango.SCALE,
                  inkP.y/Pango.SCALE);
            print("log: %dx%d@(%d,%d)\n", logicalP.width/Pango.SCALE,
                  logicalP.height/Pango.SCALE, logicalP.x/Pango.SCALE,
                  logicalP.y/Pango.SCALE);

            // TODO figure out how to use X and Y, which may be nonzero
            cr.rel_move_to(0, (logicalP.y + logicalP.height)/Pango.SCALE);

            // XXX DEBUG
            print("Render block: <[%s]>\n", final_markup);
            return RenderResult.COMPLETE;
        } // render_simple()

        /**
         * Render this block at the current position on the context.
         *
         * The caller must set the current position to the left margin
         * of this block before calling this method.
         *
         * rightP and bottomP are not hard limits, but say where the margins
         * are:
         * * Text rendered to the right of rightP is in the right margin.
         * * Text rendered below bottomP is in the bottom margin.
         *
         * This function must not be called on two blocks at the same time
         * if those blocks share a layout instance.
         *
         * @param cr        The context to render into
         * @param rightP    The right limit, in Pango units
         * @param bottomP   The bottom limit, in Pango units
         */
        public virtual RenderResult render(Cairo.Context cr,
            double rightP, double bottomP)
        {
            return render_simple(cr, layout, rightP, bottomP,
                       markup + post_markup);
        }

        public Blk(Pango.Layout layout)
        {
            this.layout = layout;
        }

    } // class Blk

    /**
     * A block that renders a bullet and a text block
     */
    public class BulletBlk : Blk
    {
        /** The markup for the bullet */
        private string bullet_markup;

        public BulletBlk(Pango.Layout layout, string bullet_markup)
        {
            base(layout);
            this.bullet_markup = bullet_markup;
        }

        public override RenderResult render(Cairo.Context cr,
            double rightP, double bottomP)
        {
            // TODO render the bullet, then render the markup
            return render_simple(cr, layout, rightP, bottomP,
                       GLib.Log.METHOD + ": not yet implemented\n" + markup + post_markup);
        }
    } // class BulletBlk

}} //namespaces
