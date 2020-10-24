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

    /** Stringify a Pango.Rectangle for debugging */
    string prect_to_string(Pango.Rectangle rect)
    {
        return "at (%f,%f); size %fx%f".printf(
            p2i(rect.x), p2i(rect.y),
            p2i(rect.width), p2i(rect.height)
        );
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
             *
             * Leaves the current position at the right side of the rendering.
             * This is because shapes are inline (span-like), so there is
             * more text following the shape, in the general case.
             *
             * @param cr        The Cairo context
             * @param do_path   See CairoShapeRendererFunc
             */
            public abstract void render(Cairo.Context cr, bool do_path);

            /** Clone this shape */
            public abstract Shape.Base clone();

        } // class Base

        /**
         * An image.
         *
         * This class is based on C code by Mike Birch, which code he kindly
         * placed in the public domain.  [[https://immortalsofar.com/PangoDemo/]].
         */
        public class Image : Base {
            /**
             * The ink rectangle, in Pango units.
             */
            private Pango.Rectangle? inkP = null;

            private int paddingP_stg;

            /** The size of the padding */
            public int paddingP {
                get {
                    return paddingP_stg;
                }
                set {
                    paddingP_stg = value;
                    populate_rects();
                }
            }

            /** Default padding */
            public const double DEFAULT_PADDING_IN = 0.05;

            /**
             * The logical rectangle, including padding
             *
             * The logical rectangle is the ink rectangle plus padding on
             * the top, left, and right.
             */
            private Pango.Rectangle? logicalP = null;

            private Cairo.ImageSurface image;

            private void populate_rects()
            {
                int wdP = c2p(image.get_width());
                int htP = c2p(image.get_height());
                logicalP = Pango.Rectangle();
                logicalP.x = 0;
                logicalP.y = -(htP + paddingP);
                logicalP.width = wdP + 2*paddingP;
                logicalP.height = htP + paddingP;

                inkP = Pango.Rectangle();
                inkP.x = paddingP;
                inkP.y = -htP;  // Bottom of the image sits on the baseline
                inkP.width = wdP;
                inkP.height = htP;

            }

            public override Pango.Rectangle get_inkP()
            {
                if(inkP == null) {
                    populate_rects();
                }
                return inkP;
            }

            public override Pango.Rectangle get_logicalP()
            {
                if(inkP == null) {
                    populate_rects();
                }
                return logicalP;
            }

            public override void render(Cairo.Context cr, bool do_path)
            {
                assert(!do_path);   // XXX handle this more gracefully

                double leftC, topC; // Where we started
                cr.get_current_point(out leftC, out topC);

                // Figure out where to put the image.  Use the ink rectangle
                // so that changes to the business logic are only in populate_rects().
                double img_topC, img_leftC, img_wC, img_hC, img_log_widthC;

                var inkP = get_inkP();

                img_topC = topC + p2c(inkP.y);
                img_leftC = leftC + p2c(inkP.x);
                img_wC = p2c(inkP.width);
                img_hC = p2c(inkP.height);

                var logP = get_logicalP();
                img_log_widthC = p2c(logP.x + logP.width);

                // Render the image
                cr.save();
                cr.set_antialias(NONE);

                cr.set_source_surface(image, img_leftC, img_topC);
                cr.rectangle(img_leftC, img_topC, img_wC, img_hC);
                cr.fill();

                cr.set_line_width(0.5);
                if(lenabled(TRACE)) { // ink
                    cr.set_source_rgb(1,0.5,0.5);
                    cr.rectangle(leftC + p2c(inkP.x), topC + p2c(inkP.y), p2c(inkP.width), p2c(inkP.height));
                    cr.stroke();
                }
                if(lenabled(DEBUG)) { // logical
                    cr.set_source_rgb(1,0,0);
                    cr.rectangle(leftC + p2c(logP.x), topC + p2c(logP.y), p2c(logP.width), p2c(logP.height));
                    cr.stroke();
                }
                cr.restore();
                cr.move_to(leftC + img_log_widthC, topC);
            }

            public override Shape.Base clone()
            {
                Image retval = new Image(this.image, this.paddingP);
                return retval;
            }

            /**
             * Constructor
             * @param image     The image
             * @param paddingP  The padding, in Pango units.  -1 (the default)
             *                  means to use DEFAULT_PADDING_IN.
             */
            public Image(Cairo.ImageSurface image, int paddingP = -1)
            {
                this.image = image;
                this.paddingP = (paddingP == -1) ? i2p(DEFAULT_PADDING_IN) : paddingP;
            } // ctor

            // constructors that load from files

            /**
             * Create an Image referencing an external image file.
             *
             * NOTE: at present, assumes that @href is a path from the
             * location of the source file to the location of a PNG file.
             *
             * @param href      Where the referenced image is
             * @param doc_path  Where the referencing file is.
             *                  This is a string rather than a File so it
             *                  can later be expanded to URLs.
             */
            public Image.from_href(string href, string doc_path, int paddingP = -1)
            {
                Cairo.ImageSurface s;

                string docfn = My.canonicalize_filename(doc_path); // make absolute
                string docdir = File.new_for_path(docfn).get_parent().get_path();
                string imgfn = My.canonicalize_filename(href, docdir);
                s = new Cairo.ImageSurface.from_png(imgfn);
                this(s, paddingP);
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
         * Create a layout.
         *
         * Here for convenience.  Sets wrap mode and font parameters.
         * Does not set width or text.
         *
         * @param cr        The Cairo context with which this layout will be used
         * @param fontname  The name of the font (a Pango family list and
         *                  style options)
         * @param fontsizeT The font size to use, in points.
         * @param align     The alignment of the text in the layout
         * @param justify   If true, block-justify the text in the layout.
         */
        public static Pango.Layout new_layout(Cairo.Context cr,
            string fontname, double fontsizeT, My.Alignment align = LEFT,
            bool justify = false)
        {
            var layout = Pango.cairo_create_layout(cr);
            layout.set_wrap(Pango.WrapMode.WORD_CHAR);

            // Font
            var font_description = Pango.FontDescription.from_string(
                "%s %f".printf(fontname, fontsizeT)
            );
            layout.set_font_description(font_description);

            // Paragraph
            Pango.Alignment palign = LEFT;
            switch(align) {
            case LEFT: palign = LEFT; break;
            case CENTER: palign = CENTER; break;
            case RIGHT: palign = RIGHT; break;
            default: lfixme("Invalid alignment %s", align.to_string()); break;
            }
            layout.set_alignment(palign);
            layout.set_justify(justify);

            return layout;
        } // new_layout()

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
             *
             * @param text  The actual text in the layout --- NOT the markup
             */
            protected void fill_shape_attrs(string text)
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
                if(!re.match_full(text, -1, 0, 0, out matches)) {
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

            /** Add shape_attrs to the list of attributes for a layout */
            private void append_shape_attrs_to(Pango.Layout layout)
            {
                var old_attributes = layout.get_attributes();
                if(old_attributes == null) {
                    ltraceo(this, "Setting attributes to %p", shape_attrs);
                    layout.set_attributes(shape_attrs); // OK even if shape_attrs==null
                    return;
                }

                if(shape_attrs == null) {
                    ltraceo(this, "Don't need to change the existing attrs");
                    return;
                }

                // Normal case: add to the list
                var dest = old_attributes.copy();
                var iter = shape_attrs.get_iterator();
                int entries = 0;
                while(true) {
                    var attrs = iter.get_attrs();
                    if(attrs != null) {
                        attrs.foreach((attr) => {
                            var new_attr = attr.copy();
                            ltraceo(new_attr, "Shape attr for %d", entries);
                            dest.insert((owned)new_attr);
                            ++entries;
                        });
                    }
                    if(!iter.next()) {
                        break;
                    }
                }
                ldebugo(this, "Added %d attrs", entries);

                // Refresh the layout if anything changed
                if(entries > 0) {
                    ltraceo(this, "Updating layout");
                    layout.set_attributes(dest);
                }

                if(lenabled(TRACE)) {
                    iter = layout.get_attributes().get_iterator();
                    entries = 0;
                    while(true) {
                        var attrs = iter.get_attrs();
                        if(attrs != null) {
                            attrs.foreach((attr) => {
                                ++entries;
                                ltraceo(attr, "%s %u->%u", attr.klass.type.to_string(),
                                attr.start_index, attr.end_index);
                                if(attr.klass.type == Pango.AttrType.SHAPE) {
                                    unowned Pango.AttrShape<Shape.Base> shape = (Pango.AttrShape<Shape.Base>)attr;
                                    ltraceo(attr, "  shape: ink %s log %s",
                                    prect_to_string(shape.ink_rect),
                                    prect_to_string(shape.logical_rect));
                                }
                            });
                        }
                        if(!iter.next()) {
                            break;
                        }
                    }
                    ltraceo(this, "Total %d attrs", entries);
                } // endif TRACE
            } // append_shape_attrs_to()

            /**
             * Render a shape
             */
            private void render_shape(Cairo.Context cr, Pango.AttrShape<Shape.Base> attr, bool do_path)
            {
                ldebugo(this, "Rendering shape %p", attr);
                unowned Shape.Base shape = attr.data;
                assert(shape != null);
                shape.render(cr, do_path);
            } // render_shape()

            /**
             * Render a block or portion thereof.
             *
             * This is the main routine that renders text.
             *
             * This is a helper for child classes.  If whole_markup is empty,
             * this is a no-op.  Parameters are as in render().
             *
             * Requires the layout already be initialized.
             * If any shapes are present, requires fill_shape_attrs() already have
             * been called.
             *
             * Sets nlines_rendered.
             */
            protected RenderResult render_layout(Cairo.Context cr,
                Pango.Layout layout,
                int rightP, int bottomP)
            {
                double leftC, topC; // Where we started

                // Layout coords: Origin at the upper-left of the layout;
                // positive X to the right and positive Y down.
                Pango.Rectangle layout_inkP, layout_logicalP;

                cr.get_current_point(out leftC, out topC);
                ldebugo(this,"layout %p starting at (%f, %f) limits (%f, %f)",
                    layout, c2i(leftC), c2i(topC), p2i(rightP), p2i(bottomP));

                if(get_whole_markup() == "") {
                    return RenderResult.COMPLETE;
                }

                // If this is the first time we've touched this block,
                // finalize and check the layout.
                if(nlines_rendered == 0) {

                    // Out of range
                    if(c2p(topC) >= bottomP) {
                        linfoo(this, "too low: %f >= %f",
                            c2i(topC), p2i(bottomP));
                        return RenderResult.NONE;
                    }
                    if(c2p(leftC) >= rightP ) {
                        linfoo(this, "too wide: %f >= %f",
                            c2i(leftC), p2i(rightP));
                        return RenderResult.ERROR; // too wide
                    }

                    layout.set_width(rightP - c2p(leftC));
                    layout.set_markup(get_whole_markup(), -1);

                    ltraceo(this, "layout width %f, alignment %s",
                        p2i(layout.get_width()),
                        layout.get_alignment().to_string()
                    );
                    lmemdumpo(this, "whole markup", get_whole_markup(), get_whole_markup().length);
                    lmemdumpo(this, "layout text", layout.get_text(), layout.get_text().length);

                    // Set up for shape rendering.

                    // Find the object-replacement chars.  We have to fill AFTER
                    // the set_markup() call because:
                    // - the markup includes markup tags;
                    // - the text omits those tags; and
                    // - the byte offsets are in the text, not the markup.
                    // Rather than parsing the markup ourselves, just get the text
                    // the layout is actually using.

                    fill_shape_attrs(layout.get_text());

                    append_shape_attrs_to(layout);
                    Pango.cairo_context_set_shape_renderer(
                        layout.get_context(),
                        (cr, attr, do_path)=>{ render_shape(cr, attr, do_path); }
                    );

                    layout.get_extents(out layout_inkP, out layout_logicalP);

                    if(lenabled(LOG)) {
                        llogo(this, "layout ink: %s", prect_to_string(layout_inkP));
                        llogo(this, "layout log: %s", prect_to_string(layout_logicalP));
                    }

                } else {
                    layout.get_extents(out layout_inkP, out layout_logicalP);
                } // endif need to set up the layout else

                int lineno = 0;
                int yP = c2p(topC); // Current Y

                yP += layout_logicalP.y;  // Leave room if the layout extends above its top (y=0)?
                // TODO only adjust yP on the first page of a layout?

                var iter = layout.get_iter();
                if(iter == null || iter.get_layout() == null) {
                    lerroro(this, "Invalid iterator %p!", iter);
                    return RenderResult.ERROR;
                }

                // If the iter is valid, there is at least one line (as far as
                // I can tell from inspecting the source).
                unowned Pango.LayoutLine curr_line = iter.get_line();
                bool rendered_last_line = false;
                bool did_render = false; // did we render anything during this call?

                RenderResult retval = UNKNOWN;

                // How much of the layout height was in lines we skipped
                int layout_skip_yP = 0;

                // Line coords: Origin at the UL corner of the layout;
                // positive X to the right and positive Y down.
                // The logical rect is the UL corner of the line.
                Pango.Rectangle line_inkP, line_logicalP;

                ldebugo(this, "BEGIN - %d lines in layout", layout.get_line_count());
                while(true) {   // Iterate over lines.  Manual condition checks below.

                    // Advance to the first line not yet rendered
                    if(nlines_rendered > 0 && lineno < nlines_rendered) {
                        llogo(this, "Skipping line %d", lineno);
                        iter.get_line_extents(out line_inkP, out line_logicalP);
                        layout_skip_yP = line_logicalP.y + line_logicalP.height;

                        ++lineno;
                        if(!iter.next_line()) {
                            // TODO can this happen?
                            lerroro(this, "Ran of the end of iter %p", iter);
                            return RenderResult.ERROR;  // ???
                        }

                        curr_line = iter.get_line();
                        continue;
                    }

                    // Each time through the loop, (leftC, yP) is at the
                    // upper-left corner of this line's box.

                    // Can we fit this line?
                    llogo(this, "Trying line %d", lineno);

                    iter.get_line_extents(out line_inkP, out line_logicalP);
                    if(lenabled(DEBUG)) {
                        ltraceo(this, "  ink: %s", prect_to_string(line_inkP));
                        ldebugo(this, "  log: %s", prect_to_string(line_logicalP));
                    }

                    if(yP + line_logicalP.height > bottomP) {
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

                    // Compute where everything will wind up in page coords
                    Pango.Rectangle net_inkP = {}, net_logicalP = {};

                    // The coordinates are with respect to the top of the
                    // layout, but some of the layout may be off the page.
                    // ytopP is the shift from layout to page Y.
                    int ytopP = c2p(topC) - layout_skip_yP;

                    // Similarly, the shift from layout to page X.
                    int xleftP = c2p(leftC);

                    net_logicalP.x = xleftP + line_logicalP.x;
                    net_logicalP.y = ytopP + line_logicalP.y;
                    net_logicalP.width = line_logicalP.width;
                    net_logicalP.height = line_logicalP.height;

                    net_inkP.x = xleftP + line_inkP.x;
                    net_inkP.y = ytopP + line_inkP.y;
                    net_inkP.width = line_inkP.width;
                    net_inkP.height = line_inkP.height;

                    if(lenabled(DEBUG)) { // draw the rectangles
                        cr.save();
                        cr.set_antialias(NONE);
                        cr.set_line_width(0.5);
                        if(lenabled(TRACE)) { // ink: less-saturated blue
                            cr.set_source_rgb(0.5, 0.5, 1);
                            cr.rectangle(
                                p2c(net_inkP.x),
                                p2c(net_inkP.y),
                                p2c(net_inkP.width),
                                p2c(net_inkP.height)
                            );
                            cr.stroke();
                        }
                        if(lenabled(DEBUG)) { // logical: more-saturated blue
                            cr.set_source_rgb(0,0,1);
                            cr.rectangle(
                                p2c(net_logicalP.x),
                                p2c(net_logicalP.y),
                                p2c(net_logicalP.width),
                                p2c(net_logicalP.height)
                            );
                            cr.stroke();
                        }
                        cr.restore();
                    }

                    // Render this line
                    // Move vertically to the baseline, which is the vertical
                    // reference for the line.
                    int this_xP = net_logicalP.x;
                    int this_yP = net_logicalP.y;

                    // get_line_extents gives us bounding rectangles, but not
                    // the baseline.  We have to get the baseline from the
                    // line's extents.
                    curr_line.get_extents(out line_inkP, out line_logicalP);
                    this_yP -= line_logicalP.y;

                    ldebugo(this, "  - Rendering line %d, UL corner y %f", lineno, p2i(yP));
                    llogo(this, "    Rendering at (%f, %f)", p2i(this_xP), p2i(this_yP));

                    cr.move_to(p2c(this_xP), p2c(this_yP));
                    Pango.cairo_show_layout_line(cr, curr_line); // UNSETS the current point
                    did_render = true;

                    // Advance to the next line
                    yP += line_logicalP.height;
                    cr.move_to(leftC, p2c(yP));

                    if(lenabled(DEBUG)) {
                        double currxC, curryC;
                        cr.get_current_point(out currxC, out curryC);
                        ldebugo(this,"  now at (%f,%f) %s", c2i(currxC), c2i(curryC),
                            cr.has_current_point() ? "has pt" : "no pt");
                    }

                    if(!iter.next_line()) {
                        rendered_last_line = true;
                        break;
                    }
                    ++lineno;
                    curr_line = iter.get_line();
                } // for each line

                if(rendered_last_line) {
                    // we finished the block while we were on this page
                    nlines_rendered = 0;
                    retval = COMPLETE;

                    // Move the Pango current point to the bottom-left of the
                    // last line's logical rectangle
                    cr.move_to(leftC, p2c(yP));
                }

                ldebugo(this, "END - rendered %d lines - %s",
                    nlines_rendered, retval.to_string());

                return retval;
            } // render_layout()

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
                return render_layout(cr, layout, rightP, bottomP);
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
                var result = render_layout(cr, layout, rightP, bottomP);

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

                return result; // COMPLETE or PARTIAL from render_layout()
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
                var result = render_layout(cr, layout, rightP, bottomP);
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
