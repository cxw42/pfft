// writer/pango-blocks.vala
//
// Blocks of content
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My.Log;

namespace My {
    /** Return the string representing _codepoint_ */
    public string U(uint codepoint)
    {
        return ((unichar)codepoint).to_string();
    }

    /**
     * Results of a render call
     *
     * This is the return value of My.Shape.Base.render() and
     * My.Blocks.Blk.render().
     */
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


    /** Shapes that can be rendered inline with text */
    namespace Shape {
        /**
         * Base class for shapes
         *
         * TODO make this an interface instead?
         */
        public abstract class Base : Object {
            /** The ink rectangle for this shape */
            public abstract Pango.Rectangle get_inkP();
            /** The logical rectangle for this shape */
            public abstract Pango.Rectangle get_logicalP();

            /**
             * Render this shape at the current position.
             * @param cr        The Cairo context
             * @param do_path   See CairoShapeRendererFunc
             *
             * Leaves the current position at the right side of the rendering.
             * This is because shapes are inline (span-like), so there is
             * more text following the shape, in the general case.
             */
            public abstract void render(Cairo.Context cr, bool do_path);

            /** Clone this shape */
            public abstract Shape.Base clone();

        } // class Base

        /** An image */
        public class Image : Base {
            /**
             * The bounding rectangle, in Pango units.
             *
             * This class uses the same rectangle for both ink and logical.
             */
            private Pango.Rectangle? rectP = null;
            private Cairo.ImageSurface image;

            private void populate_rectP()
            {
                rectP = Pango.Rectangle();
                rectP.x = 0;
                rectP.y = 0;    // TODO?  Baseline?
                rectP.width = c2p(image.get_width());
                rectP.height = c2p(image.get_height());
            }

            public override Pango.Rectangle get_inkP()
            {
                if(rectP == null) {
                    populate_rectP();
                }
                return rectP;
            }

            public override Pango.Rectangle get_logicalP()
            {
                return get_inkP();
            }

            public override void render(Cairo.Context cr, bool do_path)
            {
                double leftC, topC; // Where we started
                double wC = image.get_width();
                double hC = image.get_height();
                assert(!do_path);   // XXX handle this more gracefully

                cr.get_current_point(out leftC, out topC);

                cr.save();
                cr.set_antialias(NONE);
                cr.set_line_width(0.5);
                cr.set_source_rgb(1,0,0);

                cr.rectangle(leftC, topC, wC, hC);
                cr.stroke();

                cr.move_to(leftC, topC);
                cr.line_to(leftC+wC, topC+hC);
                cr.stroke();

                cr.set_source_surface(image, leftC, topC);
                cr.rectangle(leftC, topC, wC, hC);
                cr.fill();

                cr.restore();
                cr.move_to(leftC+wC, topC);
            }

            public override Shape.Base clone()
            {
                Image retval = new Image(this.image);
                return retval;
            }

            /** Constructor */
            public Image(Cairo.ImageSurface image)
            {
                this.image = image;
            } // ctor

            // constructors that load from files

            /**
             * Create an Image referencing an external image file.
             * @param href      Where the referenced image is
             * @param doc_path  Where the referencing file is.
             *                  This is a string rather than a File so it
             *                  can later be expanded to URLs.
             *
             * NOTE: at present, assumes that @href is a path from the
             * location of the source file to the location of a PNG file.
             */
            public Image.from_href(string href, string doc_path)
            {
                Cairo.ImageSurface s;

                string docfn = Filename.canonicalize(doc_path); // make absolute
                string docdir = File.new_for_path(docfn).get_parent().get_path();
                string imgfn = Filename.canonicalize(href, docdir);
                s = new Cairo.ImageSurface.from_png(imgfn);
                this(s);
                llogo(this, "Loaded %s (%s relative to %s): %p, %f x %f",
                    imgfn, href, doc_path, s,
                    c2i(image.get_width()), c2i(image.get_height()));
            } // Image.from_href()

        } // class Image
    } // namespace Shape

    namespace Blocks {

        /** Placeholder character used for images */
        public string OBJ_REPL_CHAR()
        {
            return U(0xfffc); // Unicode OBJECT REPLACEMENT CHARACTER
        }

        /** Types of bullets/numbers */
        public enum IndentType {
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

            private static string aplus(uint offset)
            {
                return ((unichar)((int)'a' + offset)).to_string();
            }

            private static string alpha(uint num) requires(num >= 1)
            {
                // Modified from https://www.perlmonks.org/?node_id=1168587 by
                // MidLifeXis, https://www.perlmonks.org/?node_id=272364
                var sb = new StringBuilder();
                uint n = num - 1; // shift to 0-based
                uint adj = 0;   // 0 the first time through, then -1

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
                int j, k; // mysterious indices into `control`
                uint u, v; // mysterious numbers
                j = 0;
                v = 1000;

                while(true) {
                    while(num >= v) {
                        sb.append_c(control[j]);
                        num -= v;
                    }
                    if(num <= 0) { // nonpositive input produces no output
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

            /** A cached version of markup + post_markup */
            private string whole_markup = null;

            /** Return the cached markup + post_markup */
            protected string get_whole_markup()
            {
                if(whole_markup == null) {
                    whole_markup = markup + post_markup;
                    fill_shape_attrs();
                }
                return whole_markup;
            }

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
             * List of "shapes", i.e., non-text elements to be rendered inline
             * with the text.
             *
             * These are represented in text by OBJ_REPL_CHAR.
             */
            protected Gee.LinkedList<Shape.Base> shapes = null;

            /** Add an object to the list of elements to be rendered separately */
            public void add_shape(Shape.Base shape)
            {
                if(shapes == null) {
                    shapes = new Gee.LinkedList<Shape.Base>();
                }
                shapes.add(shape);
            } // add_shape()

            /** Attributes representing the shapes */
            protected Pango.AttrList shape_attrs = null;

            /**
             * Initialize shape_attrs.
             *
             * Call only when the markup for the block has been finalized and
             * all add_shape() calls have been made.
             */
            protected void fill_shape_attrs()
            {
                shape_attrs = new Pango.AttrList();
                if(shapes == null || shapes.is_empty) {
                    return;
                }

                // check if the number of OBJ_REPL_CHARs in whole_markup
                // is the same as the number of shapes
                int[] start_offset_bytes = {};
                int[] end_offset_bytes = {};
                var re = new Regex(OBJ_REPL_CHAR());    // TODO move out of this fn, or handle/forward the RegexError
                MatchInfo matches;
                // lmemdumpo(this, "OBJ_REPL_CHAR", OBJ_REPL_CHAR(), OBJ_REPL_CHAR().length);
                // lmemdumpo(this, "whole_markup", get_whole_markup(), get_whole_markup().length);
                if(!re.match_full(get_whole_markup(), -1, 0, 0, out matches)) {
                    lerroro(this, "No obj repl chars");
                    assert(false);  // TODO
                }
                int shapeidx = -1;
                while(matches.matches()) {
                    ++shapeidx;
                    int start_pos, end_pos;
                    if(!matches.fetch_pos(0, out start_pos, out end_pos)) {
                        lerroro(this, "Could not fetch match position");
                        assert(false);  // TODO
                    }
                    ltraceo(this, "shape %d repl char %d->%d", shapeidx, start_pos, end_pos);
                    start_offset_bytes += start_pos;
                    end_offset_bytes += end_pos;
                    matches.next();
                }

                if(start_offset_bytes.length != shapes.size) {
                    lerroro(this, "Wrong number of obj repl chars/shapes");
                    assert(false);  // TODO
                }
                ltraceo(this, "Found %d match(es)", start_offset_bytes.length);

                shapeidx = -1;
                foreach(var shape in shapes) {
                    ++shapeidx;
                    var attr = new Pango.AttrShape<Shape.Base>.with_data(
                        shape.get_inkP(), shape.get_logicalP(), shape,
                        (data)=>{ return data.clone();} );

                    // byte offsets of the placeholder
                    attr.start_index = start_offset_bytes[shapeidx];
                    attr.end_index = end_offset_bytes[shapeidx];


                    shape_attrs.insert((owned)attr);
                }

            } // fill_shape_attrs()

            /**
             * Render a shape
             */
            private void render_shape(Cairo.Context cr, Pango.AttrShape<Shape.Base> attr, bool do_path)
            {
                ldebugo(this, "Rendering shape %p", attr);
                unowned Shape.Base shape = attr.data;
                assert(shape != null);
                shape.render(cr, do_path);

                /*
                double leftC, topC;
                cr.get_current_point(out leftC, out topC);
                cr.save();
                cr.restore();
                cr.move_to(topC, leftC + XXX);
                */
            } // render_shape()

            /**
             * Render a portion of a block
             *
             * Parameters are as render().  Sets nlines_rendered.
             * Requires the layout already be initialized.
             * If any shapes are present, requires fill_shape_attrs() already have
             * been called.
             */
            protected RenderResult render_partial(Cairo.Context cr,
                Pango.Layout layout,
                double leftC, double topC,
                int rightP, int bottomP)
            ensures(result == COMPLETE || result == PARTIAL || result == NONE)
            {
                int lineno = 0;
                int yP = c2p(topC); // Current Y
                unowned SList<Pango.LayoutLine> lines = layout.get_lines_readonly();
                unowned SList<Pango.LayoutLine> curr_line = lines;
                int last_bottom_yP = 0; // bottom of the last-rendered line
                bool first_line = true;
                bool did_render = false; // did we render anything during this call?

                RenderResult retval = UNKNOWN;

                ldebugo(this, "render_partial BEGIN - %u lines in layout", lines.length());
                while(curr_line != null) {

                    // Advance to the first line not yet rendered
                    // TODO double-check that this works -- it appears that we
                    // might be skipping lines sometimes.
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

                    if(lenabled(DEBUG)) {
                        ltraceo(this, "  ink: %fx%f@(%f,%f)", p2i(inkP.width),
                            p2i(inkP.height), p2i(inkP.x), p2i(inkP.y));
                        ldebugo(this, "  log: %fx%f@(%f,%f)", p2i(logicalP.width),
                            p2i(logicalP.height), p2i(logicalP.x), p2i(logicalP.y));
                    }

                    if(yP + logicalP.y + logicalP.height > bottomP) {
                        // Done with what we can do for this page.
                        // At least the current line is left, so this block is
                        // not yet complete.
                        nlines_rendered = lineno;
                        retval = did_render ? RenderResult.PARTIAL : RenderResult.NONE;
                        // TODO if nlines_rendered > 0, should we always return
                        // PARTIAL since some of the block has already been
                        // rendered?
                        break;
                    }

                    if(lenabled(DEBUG)) { // render the rectangles
                        cr.save();
                        cr.set_antialias(NONE);
                        cr.set_line_width(0.5);
                        if(lenabled(TRACE)) { // ink
                            cr.set_source_rgb(1,0,0);
                            cr.rectangle(leftC+p2c(inkP.x), p2c(yP+inkP.y), p2c(inkP.width), p2c(inkP.height));
                            cr.stroke();
                        }
                        if(lenabled(DEBUG)) { // logical
                            cr.set_source_rgb(0,0,1);
                            cr.rectangle(leftC+p2c(logicalP.x), p2c(yP+logicalP.y), p2c(logicalP.width), p2c(logicalP.height));
                            cr.stroke();
                        }
                        cr.restore();
                    }

                    // Render this line
                    ldebugo(this, "Rendering line %d at %f\"", lineno, p2i(yP));
                    cr.move_to(leftC, p2c(yP));
                    Pango.cairo_show_layout_line(cr, curr_line.data); // UNSETS the current point
                    did_render = true;
                    last_bottom_yP = yP + logicalP.y + logicalP.height;

                    // Advance to the next line
                    yP += logicalP.height;
                    cr.move_to(leftC, p2c(yP));

                    if(lenabled(DEBUG)) {
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
             * This is a helper for child classes.  If whole_markup is empty,
             * this is a no-op.  Parameters are as in render().
             *
             * This respects nlines_rendered and invokes render_partial() if needed.
             *
             * TODO just use render_partial --- the code duplication is not
             * worth the potential speed increase in my use case.
             */
            protected RenderResult render_simple(Cairo.Context cr,
                Pango.Layout layout,
                int rightP, int bottomP)
            {
                double leftC, topC; // Where we started

                if(get_whole_markup() == "") {
                    return RenderResult.COMPLETE;
                }

                cr.get_current_point(out leftC, out topC);
                ldebugo(this,"render_simple layout %p starting at (%f, %f) limits (%f, %f)",
                    layout, c2i(leftC), c2i(topC), p2i(rightP), p2i(bottomP));

                if(nlines_rendered > 0) {
                    // we already did part, so do the next part.  This may not be
                    // the whole rest of the block, if the block's text is longer
                    // than a page.
                    return render_partial(cr, layout, leftC, topC, rightP, bottomP);
                }

                // Out of range
                if(c2p(topC) >= bottomP) {
                    return RenderResult.NONE;
                }
                if(c2p(leftC) >= rightP ) {
                    linfoo(this, "render_simple: too wide: %f >= %f",
                        c2i(leftC), p2i(rightP));
                    return RenderResult.ERROR; // too wide
                }

                layout.set_width(rightP - c2p(leftC));
                layout.set_markup(get_whole_markup(), -1);

                // check metrics and see if we are at risk of running
                // off the page vertically

                Pango.Rectangle inkP, logicalP;
                layout.get_extents(out inkP, out logicalP);
                if(topC + p2c(logicalP.y + logicalP.height) >= p2c(bottomP)) {
                    lwarningo(this, "Not enough room for the whole block: %f > %f",
                        c2i(topC + p2c(logicalP.y + logicalP.height)),
                        p2i(bottomP));
                    return render_partial(cr, layout, leftC, topC, rightP, bottomP);
                }

                if(lenabled(DEBUG)) {
                    ltraceo(this, "ink: %fx%f@(%f,%f)", p2i(inkP.width),
                        p2i(inkP.height), p2i(inkP.x),
                        p2i(inkP.y/Pango.SCALE));
                    ldebugo(this, "log: %fx%f@(%f,%f)", p2i(logicalP.width),
                        p2i(logicalP.height), p2i(logicalP.x),
                        p2i(logicalP.y));
                }

                // Set up for shape rendering.  For some reason, calling this
                // at the beginning of this function did not take effect.
                Pango.cairo_context_set_shape_renderer(
                    layout.get_context(),
                    (cr, attr, do_path)=>{ render_shape(cr, attr, do_path); }
                );
                ldebugo(this, "Context %p", layout.get_context());
                layout.set_attributes(shape_attrs);
                if(lenabled(DEBUG)) {
                    // Can't use shape_attrs.get_attributes() because it's Pango 1.44+
                    var iter = shape_attrs.get_iterator();
                    int entries = 0;
                    while(iter.next()) {
                        ++entries;
                    }
                    ldebugo(this, "Attr list has %d entries", entries);
                }

                // Render
                Pango.cairo_show_layout(cr, layout);

                if(lenabled(DEBUG)) { // render the rectangles
                    cr.save();
                    cr.set_antialias(NONE);
                    cr.set_line_width(0.5);
                    if(lenabled(TRACE)) { // ink
                        cr.set_source_rgb(1,0,0);
                        cr.rectangle(leftC+p2c(inkP.x), topC+p2c(inkP.y), p2c(inkP.width), p2c(inkP.height));
                        cr.stroke();
                    }
                    if(lenabled(DEBUG)) { // logical
                        cr.set_source_rgb(0,0,1);
                        cr.rectangle(leftC+p2c(logicalP.x), topC+p2c(logicalP.y), p2c(logicalP.width), p2c(logicalP.height));
                        cr.stroke();
                    }
                    cr.restore();
                }

                // Move down the page
                cr.move_to(leftC,
                    topC + p2c(logicalP.y + logicalP.height));

                // ldebugo(this, "Render block: <[%s]>", get_whole_markup());
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
                return render_simple(cr, layout, rightP, bottomP);
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
            /**
             * A layout for the bullet.
             *
             * We need this so that we don't trash the main layout between pages
             * if the block splits across pages.
             */
            private Pango.Layout bullet_layout;

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

            public BulletBlk(Pango.Layout layout, Pango.Layout bullet_layout,
                string bullet_markup, int bullet_leftP, int text_leftP)
            requires(text_leftP > bullet_leftP)
            {
                base(layout);

                this.bullet_layout = bullet_layout;
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
                if(get_whole_markup() == "") {
                    return RenderResult.COMPLETE;
                }

                double xC, yC, leftC, topC;
                cr.get_current_point(out leftC, out topC);
                if(lenabled(DEBUG)) { // DEBUG
                    llogo(this, "Pre-render at (%f, %f)", c2i(leftC), c2i(topC));
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
                var result = render_simple(cr, layout, rightP, bottomP);

                // Move back to where the next block will start
                cr.get_current_point(out xC, out yC); // where the copy left us
                cr.move_to(leftC, yC);

                if(!is_first_chunk) { // Nothing more to do
                    return result;
                }
                if(result == NONE) { // None of the block fit on the page
                    return result;
                }

                // Something rendered on the first page, so render the bullet.
                // TODO shift the bullet down so it is centered on the first
                // line of the text.
                ldebugo(this, "Rendering bullet from layout %p - post-render at (%f, %f)",
                    bullet_layout, c2i(xC), c2i(yC));
                cr.move_to(leftC + p2c(bullet_leftP), topC);
                bullet_layout.set_width(text_leftP - bullet_leftP);
                bullet_layout.set_markup(bullet_markup, -1);
                Pango.cairo_show_layout(cr, bullet_layout);

                cr.move_to(leftC, yC);
                ldebugo(this, "Rendered bullet - now at (%f, %f)", c2i(leftC), c2i(yC));

                return result; // COMPLETE or PARTIAL from render_simple()
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
            private int heightP = c2p(12); // 12 pt --- assumes points for Cairo units

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
                double xC, yC; // Cairo current points (Cairo.PdfSurface units are pts)
                double leftC; // left margin
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
                cr.set_line_width(0.75); // pt, I think
                cr.move_to(leftC + p2c(leftP), yC + heightC*0.5);
                cr.line_to(p2c(rightP), yC + heightC*0.5);
                cr.stroke();
                cr.restore();

                // move 12 pts. down.  TODO make the vertical size a parameter.
                cr.move_to(leftC, yC + heightC);

                // ldebugo(this, "Render rule\n");
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
                if(get_whole_markup() == "") {
                    return RenderResult.COMPLETE;
                }

                double x1C, y1C; // Starting points
                double x2C, y2C; // Ending points of the text block

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
                var result = render_simple(cr, layout, rightP, bottomP);
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

    } // namespace Blocks
} // namespace My
