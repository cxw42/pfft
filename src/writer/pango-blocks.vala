// writer/pango-blocks.vala
//
// Blocks of content
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My { namespace Blocks {

    /** Types of bullets/numbers */
    private enum IndentType {
        /* --- Bullets --- */
        BLACK_CIRCLE,
        WHITE_CIRCLE,
        BLACK_SQUARE,
        WHITE_SQUARE,
        BLACK_DIAMOND,
        WHITE_DIAMOND,
        BLACK_TRIANGLE,

        /* --- Numbers --- */
        /** 0..9 */
        ENGLISH_DIGITS,
        /** a..z */
        LOWERCASE_ALPHA,
        /** i, ii, ... */
        LOWERCASE_ROMAN,
        /** A..Z */
        UPPERCASE_ALPHA,
        /** I, II, ... */
        UPPERCASE_ROMAN,

        LAST_BULLET = BLACK_TRIANGLE;

        public bool is_bullet()
        {
            return this <= LAST_BULLET;
        }

        private static string U(uint codepoint)
        {
            return ((unichar)codepoint).to_string();
        }

        private string alpha(uint num) requires(num >= 1)
        {
            // TODO FIXME: after z comes ba rather than aa.

            if(num==1) {
                return "a";
            }

            uint n = num - 1;
            var sb = new StringBuilder();
            while(n>0) {
                sb.prepend(
                    ((unichar)((int)'a' + n%26)).to_string()
                );
                n /= 26;
            }
            return sb.str;
        }

        private string roman(uint num)
        {
            // Knuth's algorithm for Roman numerals, from TeX.  Quoted by
            // Hans Wennborg at https://www.hanshq.net/roman-numerals.html.
            // Converted to Vala by Chris White (github.com/cxw42)

            var sb = new StringBuilder();

            string control = "m2d5c2l5x2v5i";
            int j, k;   // mysterious indices into `control`
            uint u, v;  // mysterious numbers
            j = 0;
            v = 1000;

            while(true) {
                while(num >= v) {
                    sb.append_c(control[j]);
                    num -= v;
                }
                if(num <= 0) {  // nonpositive input produces no output
                    break;
                }

                k = j+2;
                u = v / control[k-1].digit_value();
                if(control[k-1] == '2') {
                    k += 2;
                    u /= control[k-1].digit_value();
                }

                if(num+u >= v) {
                    sb.append_c(control[k]);
                    num += u;
                } else {
                    j += 2;
                    v /= control[j-1].digit_value();
                }
            }

            return sb.str;
        } // roman()

        public string render(uint num)
        {

            switch(this) {
            case BLACK_CIRCLE:
                return U(0x25cf);
            case WHITE_CIRCLE:
                return U(0x25cb);
            case BLACK_SQUARE:
                return U(0x25a0);
            case WHITE_SQUARE:
                return U(0x25a1);
            case BLACK_DIAMOND:
                return U(0x25c6);
            case WHITE_DIAMOND:
                return U(0x25c7);
            case BLACK_TRIANGLE:
                return U(0x2023);

            /* --- Numbers --- */
            /* a..z */
            case LOWERCASE_ALPHA:
                return alpha(num);
            /* i... */
            case LOWERCASE_ROMAN:
                return roman(num);
            /* A..Z */
            case UPPERCASE_ALPHA:
                return alpha(num).ascii_up();
            /* I... */
            case UPPERCASE_ROMAN:
                return roman(num).ascii_up();
            case ENGLISH_DIGITS:
            default:
                return num.to_string();
            }
        }
    } // enum IndentType

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
        font_description.set_size((int)(12 * Pango.SCALE));
        // 12-pt text on a Cairo surface that uses points as its units,
        // e.g., PDFs.
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
            cr.get_current_point(out xC, out yC);
            cr.rel_move_to(-xC + 72, (logicalP.y + logicalP.height)/Pango.SCALE);
            // 72 = left margin. XXX HACK

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

        /** The left edge of the bullet */
        private int bullet_leftP;

        /**
         * The left edge of the text.
         *
         * Must be less than bullet_leftP.
         */
        private int text_leftP;

        public BulletBlk(Pango.Layout layout, string bullet_markup,
            int bullet_leftP, int text_leftP)
        requires(text_leftP > bullet_leftP)
        {
            base(layout);

            this.bullet_markup = bullet_markup;
            this.bullet_leftP = bullet_leftP;
            this.text_leftP = text_leftP;
        }

        /**
         * Render the bullet and the text.
         *
         * This function ignores the current Cairo X position.
         */
        public override RenderResult render(Cairo.Context cr,
            double rightP, double bottomP)
        {
            string final_markup = markup + post_markup;

            if(final_markup == "") {
                return RenderResult.COMPLETE;
            }

            double xC, yC;  // Cairo current points (Cairo.PdfSurface units are pts)
            double xP, yP;
            cr.get_current_point(out xC, out yC);
            xP = xC * Pango.SCALE;
            yP = yC * Pango.SCALE;

            // Out of range
            if(xP >= rightP || yP >= bottomP || bullet_leftP >= rightP ||
                text_leftP >= rightP) {
                return RenderResult.ERROR;
            }

            // TODO check metrics and see if we are at risk of running
            // off the page

            // TODO render the bullet
            cr.move_to((double)bullet_leftP/Pango.SCALE, yC);
            layout.set_width(text_leftP - bullet_leftP);
            layout.set_markup(bullet_markup, -1);
            Pango.cairo_show_layout(cr, layout);

            // Render the markup
            cr.move_to((double)text_leftP/Pango.SCALE, yC);
            return render_simple(cr, layout, rightP, bottomP, final_markup);
        }
    } // class BulletBlk

    // TODO block quotes, rules

}} // namespaces
