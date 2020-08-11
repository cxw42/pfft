// writer/pango-blocks.vala
//
// Blocks of content
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My.Log;

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

        // Return the string representing _codepoint_
        private static string U(uint codepoint)
        {
            return ((unichar)codepoint).to_string();
        }

        private static string aplus(uint offset)
        {
            return ((unichar)((int)'a' + offset)).to_string();
        }

        private static string alpha(uint num) requires(num >= 1)
        {
            // Modified from https://www.perlmonks.org/?node_id=1168587 by
            // MidLifeXis, https://www.perlmonks.org/?node_id=272364
            var sb = new StringBuilder();
            uint n = num - 1;   // shift to 0-based
            uint adj = 0;       // 0 the first time through, then -1

            do {
                sb.prepend(aplus(n%26 + adj));
                n /= 26;
                adj = -1;
            } while(n>0);

            return sb.str;
        }

        private static string roman(uint num)
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

        private static string smallU(uint codepoint)
        {
            return @"<span size=\"xx-small\">$(U(codepoint))</span>";
        }

        /**
         * Render _num_ in the style of _this_
         * @return Pango markup
         */
        public string render(uint num)
        {

            switch(this) {
            case BLACK_CIRCLE:
                return smallU(0x25cf);
            case WHITE_CIRCLE:
                return smallU(0x25cb);
            case BLACK_SQUARE:
                return smallU(0x25a0);
            case WHITE_SQUARE:
                return smallU(0x25a1);
            case BLACK_DIAMOND:
                return smallU(0x25c6);
            case WHITE_DIAMOND:
                return smallU(0x25c7);
            case BLACK_TRIANGLE:
                return smallU(0x2023);

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

    ///////////////////////////////////////////////////////////////////////

    /** Results of a Blk.render() call */
    public enum RenderResult {
        /** Other error */
        ERROR,
        /** The whole block was rendered */
        COMPLETE,
        /** There is more to render, e.g., on the next page */
        PARTIAL,
        /** None of the block fit on the page */
        NONE,
        /** Unknown status */
        UNKNOWN,
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
        font_description.set_size(12 * Pango.SCALE); // 12-pt text
        layout.set_wrap(Pango.WrapMode.WORD_CHAR);

        return layout;
    } // new_layout_12pt()

    ///////////////////////////////////////////////////////////////////////

    /**
     * Block of content to be written.
     *
     * Blk itself knows how to render body paragraphs.  It also serves as the
     * base class for more specialized blocks.
     *
     * All dimensions within a Blk instance are relative to the left
     * margin, which is provided to render().  All parameters to render()
     * are relative to the page.
     *
     * Blk and its children assume that only one Blk instance will be
     * rendered at a time.
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
         * How many lines of the content have already been rendered.
         *
         * The use of this is up to child classes.
         */
        protected int nlines_rendered = 0;

        /**
         * Render a portion of a block
         *
         * Parameters are as render().  Sets nlines_rendered.
         * Requires the layout already be initialized.
         */
        protected RenderResult render_partial(Cairo.Context cr,
            Pango.Layout layout,
            double leftC, double topC,
            int rightP, int bottomP, string final_markup)
        ensures(result == COMPLETE || result == PARTIAL)
        {
            int lineno = 0;
            int yP = c2p(topC);  // Current Y
            unowned var lines = layout.get_lines_readonly();
            unowned SList<Pango.LayoutLine> curr_line = lines;
            int last_bottom_yP = 0; // bottom of the last-rendered line
            bool first_line = true;

            RenderResult retval = UNKNOWN;

            ldebugo(this, "render_partial BEGIN %s", this.get_type().name());
            while(curr_line != null) {

                // Advance to the first line not yet rendered
                if(nlines_rendered > 0 && lineno < nlines_rendered) {
                    llogo(this, "Skipping line %d", lineno);
                    ++lineno;
                    curr_line = curr_line.next;
                    continue;
                }

                // Can we fit this line?
                llogo(this, "Trying line %d", lineno);
                Pango.Rectangle inkP, logicalP;
                curr_line.data.get_extents(out inkP, out logicalP);

                if(first_line) {
                    // The line's box is with respect to the baseline, NOT
                    // the upper-left corner of the text block.
                    // Adjust yP to compensate.
                    yP -= logicalP.y;
                    first_line = false;
                }

                if(lenabled(DEBUG)) { // DEBUG
                    ldebugo(this, "  ink: %fx%f@(%f,%f)", p2i(inkP.width),
                        p2i(inkP.height), p2i(inkP.x), p2i(inkP.y));
                    ldebugo(this, "  log: %fx%f@(%f,%f)", p2i(logicalP.width),
                        p2i(logicalP.height), p2i(logicalP.x), p2i(logicalP.y));
                }

                // TODO FIXME: if only a partial line fits on this page,
                // and it's the first line, we incorrectly return PARTIAL
                // instead of NONE.
                if(yP + logicalP.y + logicalP.height > bottomP) {
                    // Done with what we can do for this page.
                    // At least the current line is left, so this block is
                    // not yet complete.
                    nlines_rendered = lineno;
                    retval = PARTIAL;
                    break;
                }

                if(lenabled(DEBUG)) { // DEBUG: render the rectangles
                    cr.save();
                    cr.set_antialias(NONE);
                    cr.set_line_width(0.5);
                    if(lenabled(LOG)) { // ink
                        cr.set_source_rgb(1,0,0);
                        cr.rectangle(leftC+p2c(inkP.x), p2c(yP+inkP.y), p2c(inkP.width), p2c(inkP.height));
                        cr.stroke();
                    }
                    if(lenabled(DEBUG)) {  // logical
                        cr.set_source_rgb(0,0,1);
                        cr.rectangle(leftC+p2c(logicalP.x), p2c(yP+logicalP.y), p2c(logicalP.width), p2c(logicalP.height));
                        cr.stroke();
                    }
                    cr.restore();
                }

                // Render this line
                ldebugo(this, "Rendering line %d at %f\"", lineno, p2i(yP));
                cr.move_to(leftC, p2c(yP));
                Pango.cairo_show_layout_line(cr, curr_line.data);   // UNSETS the current point
                last_bottom_yP = yP + logicalP.y + logicalP.height;

                // Advance to the next line
                yP += logicalP.height;
                cr.move_to(leftC, p2c(yP));
                if(lenabled(DEBUG)) { // DEBUG
                    double currxC, curryC;
                    cr.get_current_point(out currxC, out curryC);
                    ldebugo(this,"  now at (%f,%f) %s", c2i(currxC), c2i(curryC),
                        cr.has_current_point() ? "has pt" : "no pt");
                }

                ++lineno;
                curr_line = curr_line.next;

            } // for each line

            if(curr_line == null) {
                // we finished the block on this page
                nlines_rendered = 0;
                retval = COMPLETE;

                // Move the Pango current point to the bottom-left of the last
                // line's logical rectangle
                cr.move_to(leftC, p2c(last_bottom_yP));
            }

            ldebugo(this,"render_partial done - rendered %d lines - %s",
                nlines_rendered, retval.to_string());

            return retval;
        } // render_partial()

        /**
         * Render a markup block with no decorations.
         *
         * This is a helper for child classes.  If final_markup is empty,
         * this is a no-op.  Parameters are as in render().
         *
         * This respects nlines_rendered and invokes render_partial() if needed.
         */
        protected RenderResult render_simple(Cairo.Context cr,
            Pango.Layout layout,
            int rightP, int bottomP, string final_markup)
        {
            double leftC, topC; // Where we started

            if(final_markup == "") {
                return RenderResult.COMPLETE;
            }

            cr.get_current_point(out leftC, out topC);
            ldebugo(this,"render_simple %s %p starting at (%f, %f) limits (%f, %f)",
                this.get_type().name(), this,
                c2i(leftC), c2i(topC), p2i(rightP), p2i(bottomP));

            if(nlines_rendered > 0) {
                // we already did part, so do the next part.  This may not be
                // the whole rest of the block, if the block's text is longer
                // than a page.
                return render_partial(cr, layout, leftC, topC, rightP, bottomP, final_markup);
            }

            // Out of range
            if(c2p(topC) >= bottomP) {
                return RenderResult.NONE;
            }
            if(c2p(leftC) >= rightP ) {
                linfoo(this, "render_simple: too wide: %f >= %f",
                        c2i(leftC), p2i(rightP));
                return RenderResult.ERROR;  // too wide
            }

            layout.set_width(rightP - c2p(leftC));
            layout.set_markup(final_markup, -1);

            // check metrics and see if we are at risk of running
            // off the page vertically

            Pango.Rectangle inkP, logicalP;
            layout.get_extents(out inkP, out logicalP);
            if(topC + p2c(logicalP.y + logicalP.height) >= p2c(bottomP)) {
                lwarningo(this, "Overflow: %f > %f",
                    c2i(topC + p2c(logicalP.y + logicalP.height)),
                    p2i(bottomP));
                return render_partial(cr, layout, leftC, topC, rightP, bottomP, final_markup);
            }

            if(lenabled(DEBUG)) { // DEBUG
                ldebugo(this, "ink: %dx%d@(%d,%d)", inkP.width/Pango.SCALE,
                    inkP.height/Pango.SCALE, inkP.x/Pango.SCALE,
                    inkP.y/Pango.SCALE);
                ldebugo(this, "log: %dx%d@(%d,%d)", logicalP.width/Pango.SCALE,
                    logicalP.height/Pango.SCALE, logicalP.x/Pango.SCALE,
                    logicalP.y/Pango.SCALE);
            }

            Pango.cairo_show_layout(cr, layout);

            if(lenabled(DEBUG)) { // DEBUG: render the rectangles
                cr.save();
                cr.set_antialias(NONE);
                cr.set_line_width(0.5);
                if(lenabled(LOG)) { // ink
                    cr.set_source_rgb(1,0,0);
                    cr.rectangle(leftC+p2c(inkP.x), topC+p2c(inkP.y), p2c(inkP.width), p2c(inkP.height));
                    cr.stroke();
                }
                if(lenabled(DEBUG)) {  // logical
                    cr.set_source_rgb(0,0,1);
                    cr.rectangle(leftC+p2c(logicalP.x), topC+p2c(logicalP.y), p2c(logicalP.width), p2c(logicalP.height));
                    cr.stroke();
                }
                cr.restore();
            }

            // Move down the page
            cr.move_to(leftC,
                topC + p2c(logicalP.y + logicalP.height));

            // ldebugo(this, "Render block: <[%s]>", final_markup); // DEBUG
            return RenderResult.COMPLETE;
        } // render_simple()

        /**
         * Render this block at the current position on the context.
         *
         * The caller must set the current position to the left margin
         * of this block before calling this method.
         *
         * This method must leave the current position at the left margin
         * and offset vertically by the amount of space consumed.
         *
         * rightP and bottomP are not hard limits, but say where the margins
         * are:
         * * Text rendered to the right of rightP is in the right margin.
         * * Text rendered below bottomP is in the bottom margin.
         *
         * This function must not be called on two blocks at the same time
         * if those blocks share a layout instance.
         *
         * This function may be called multiple times for the same block
         * if the block is split across pages.
         *
         * @param cr        The context to render into
         * @param rightP    The right limit w.r.t. the page, in Pango units
         * @param bottomP   The bottom limit w.r.t. the page, in Pango units
         */
        public virtual RenderResult render(Cairo.Context cr,
            int rightP, int bottomP)
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

        /** The left edge of the bullet, w.r.t. the left margin */
        private int bullet_leftP;

        /**
         * The left edge of the text, w.r.t. the left margin.
         *
         * Must be greater than bullet_leftP.
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
         */
        public override RenderResult render(Cairo.Context cr,
            int rightP, int bottomP)
        {
            string final_markup = markup + post_markup;

            if(final_markup == "") {
                return RenderResult.COMPLETE;
            }

            double xC, yC, leftC, topC;
            cr.get_current_point(out leftC, out topC);
            if(lenabled(DEBUG)) { // DEBUG
                llog("Now at (%f, %f)", c2i(leftC), c2i(topC));
            }

            // Out of range
            if(c2p(topC) >= bottomP) {
                return RenderResult.NONE;
            }

            if(c2p(leftC) >= rightP || c2p(leftC)+bullet_leftP >= rightP ||
                c2p(leftC)+text_leftP >= rightP) {
                lerroro(this, "bullet render(): too wide");
                return RenderResult.ERROR;
            }

            // Try to render the markup.  This will fail if we don't have room.
            cr.move_to(leftC + p2c(text_leftP), topC);
            bool is_first_chunk = (nlines_rendered == 0);
            var result = render_simple(cr, layout, rightP, bottomP, final_markup);
            if(!is_first_chunk) {   // Nothing more to do
                return result;
            }
            // TODO FIXME: after fixing render_partial, check for NONE here

            // render the bullet
            // TODO shift the bullet down so it is centered on the first
            // line of the text.
            cr.get_current_point(out xC, out yC);   // where the copy left us
            if(lenabled(DEBUG)) { // DEBUG
                ldebugo(this, "Now at (%f, %f)", c2i(xC), c2i(yC));
            }
            cr.move_to(leftC + p2c(bullet_leftP), topC);
            layout.set_width(text_leftP - bullet_leftP);
            layout.set_markup(bullet_markup, -1);
            Pango.cairo_show_layout(cr, layout);

            cr.move_to(leftC, yC);

            return result;  // COMPLETE or PARTIAL from render_simple()
        }
    } // class BulletBlk

    /**
     * A block that renders a horizontal rule
     */
    public class HRBlk : Blk
    {
        /** The left edge of the rule, w.r.t. the left margin. */
        private int leftP = 0;

        /** The amount of vertical space the rule occupies */
        private int heightP = c2p(12);  // 12 pt --- assumes points for Cairo units

        public HRBlk(Pango.Layout layout, int leftP)
        {
            base(layout);
            this.leftP = leftP;
        }

        /**
         * Render the rule
         *
         * This function ignores the current Cairo X position.
         */
        public override RenderResult render(Cairo.Context cr,
            int rightP, int bottomP)
        {
            double xC, yC;  // Cairo current points (Cairo.PdfSurface units are pts)
            double leftC;   // left margin
            double heightC = heightP/Pango.SCALE;

            cr.get_current_point(out xC, out yC);
            leftC = xC;

            // Out of range
            if(c2p(yC) >= bottomP) {
                return RenderResult.NONE;
            }
            if(c2p(xC) >= rightP || leftP >= rightP) {
                return RenderResult.ERROR;
            }

            // check metrics.  The rule is never split across pages, so
            // does not return PARTIAL.
            if(c2p(yC) + heightP >= bottomP) {
                return RenderResult.NONE;
            }

            // render the rule
            cr.save();
            cr.set_source_rgb(0,0,0);
            cr.set_line_width(0.75);    // pt, I think
            cr.move_to(leftC + p2c(leftP), yC + heightC*0.5);
            cr.line_to(p2c(rightP), yC + heightC*0.5);
            cr.stroke();
            cr.restore();

            // move 12 pts. down.  TODO make the vertical size a parameter.
            cr.move_to(leftC, yC + heightC);

            // ldebugo(this, "Render rule\n");  // XXX DEBUG
            return RenderResult.COMPLETE;
        }
    } // class HRBlk

    /**
     * A block that renders a block quote
     */
    public class QuoteBlk : Blk
    {
        /**
         * The left edge of the text, w.r.t. the left margin.
         *
         * Must be less than bullet_leftP.
         */
        private int text_leftP;

        public QuoteBlk(Pango.Layout layout, int text_leftP)
        {
            base(layout);

            this.text_leftP = text_leftP;
        }

        /**
         * Render the text and a sidebar.
         */
        public override RenderResult render(Cairo.Context cr,
            int rightP, int bottomP)
        {
            string final_markup = markup + post_markup;

            if(final_markup == "") {
                return RenderResult.COMPLETE;
            }

            double x1C, y1C;    // Starting points
            double x2C, y2C;    // Ending points of the text block

            cr.get_current_point(out x1C, out y1C);

            // Out of range
            if(c2p(x1C) >= bottomP) {
                return RenderResult.NONE;
            }
            if(c2p(x1C) >= rightP || text_leftP >= rightP) {
                return RenderResult.ERROR;
            }

            // Try to render the markup
            cr.move_to(x1C + p2c(text_leftP), y1C);
            var result = render_simple(cr, layout, rightP, bottomP, final_markup);
            if(result != COMPLETE) {
                return result;
            }

            cr.get_current_point(out x2C, out y2C);

            // render the sidebar
            double xsC = x1C + p2c(text_leftP)*0.5;
            cr.save();
            cr.set_source_rgb(0.7,0.7,0.7);
            cr.set_line_width(6.0);
            cr.move_to(xsC, y1C);
            cr.line_to(xsC, y2C);
            cr.stroke();
            cr.restore();

            cr.move_to(x1C, y2C);

            return COMPLETE;
        }
    } // class QuoteBlk

}} // namespaces
