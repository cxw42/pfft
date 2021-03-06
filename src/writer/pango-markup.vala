// writer/pango-markup.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Gee;
using My.Blocks;
using My.Log;

namespace My {

    // Unit-conversion functions -----------------------------------------
    // These are public only so they can be tested.

    /** Cairo to Pango units */
    public int c2p(double valC) {
        return (int)(valC*Pango.SCALE + 0.5);
    }

    /** Pango to Cairo units */
    public double p2c(int valP) {
        return ((double)valP)/Pango.SCALE;
    }

    /**
     * Cairo units to inches
     *
     * This assumes that a Cairo unit is a point at 72 ppi.
     * This is the case for PDF surfaces.
     */
    public double c2i(double valC) {
        return valC/72;
    }

    /**
     * Inches to Cairo units
     *
     * Same assumptions as c2i().
     */
    public double i2c(double valI) {
        return valI*72;
    }

    /** Inches to Pango units */
    public int i2p(double valI) {
        return c2p(i2c(valI));
    }

    /** Pango units to inches */
    public double p2i(int valP) {
        return c2i(p2c(valP));
    }

    // -------------------------------------------------------------------

    /**
     * Pango-markup document writer.
     *
     * Write a document by generating Pango markup for it.
     * Can write the Pango markup or the PDF.
     *
     * Caution: an instance of this class can only handle one source document.
     * Functions herein use instance data to store state and so are not
     * necessarily reentrant.
     */
    public class PangoMarkupWriter : Object, Writer {
        /** Metadata for this class */
        [Description(nick = "default", blurb = "Write PDFs using the Pango rendering library")]
        public bool meta {get; default = false; }

        /** The path to the source document */
        string source_fn_;

        /** The Cairo context for the document we are writing */
        Cairo.Context cr_ = null;

        // TODO: provide Blk instances with a layout factory instead of layouts,
        // so that each Blk can have its own layout and they won't step on
        // each other.

        /** The Pango layout for the text of the document we are writing */
        Pango.Layout layout_ = null;

        /** The Pango layout for bullets and numbers */
        Pango.Layout bullet_layout_ = null;

        /** The Pango layout for the */
        Pango.Layout pageno_layout_ = null;

        /** Current page */
        private int pageno_;

        /** True if this block is the first on the current page */
        private bool first_on_page_;

        // Rendering parameters
        [Description(nick = "Black & white", blurb = "If set, output monochrome")]
        public bool bw { get; set; default = false; }
        // TODO actually respond to bw!

        // Page parameters (unit suffixes: Inches, Cairo, Pango, poinT)
        [Description(nick = "Paper width (in.)", blurb = "Paper width, in inches")]
        public double paperwidthI { get; set; default = 8.5; }
        [Description(nick = "Paper height (in.)", blurb = "Paper height, in inches")]
        public double paperheightI { get; set; default = 11.0; }
        [Description(nick = "Left margin (in.)", blurb = "Left margin, in inches")]
        public double lmarginI { get; set; default = 1.0; }
        [Description(nick = "Top margin (in.)", blurb = "Top margin, in inches")]
        public double tmarginI { get; set; default = 1.0; }
        [Description(nick = "Text width (in.)", blurb = "Width of the text block, in inches")]
        public double hsizeI { get; set; default = 6.5; }
        [Description(nick = "Text height (in.)", blurb = "Height of the text block, in inches")]
        public double vsizeI { get; set; default = 9.0; }
        [Description(nick = "Footer margin (in.)", blurb = "Space between the bottom of the text block and the top of the footer, in inches")]
        public double footerskipI { get; set; default = 0.3; }
        [Description(nick = "Header margin (in.)", blurb = "Space between the top of the text block and the top of the header, in inches")]
        public double headerskipI { get; set; default = 0.4; }

        // Header parameters
        [Description(nick = "Header markup, left", blurb = "Pango markup for the header, left side")]
        public string headerl { get; set; default = ""; }
        [Description(nick = "Header markup, center", blurb = "Pango markup for the header, middle")]
        public string headerc { get; set; default = ""; }
        [Description(nick = "Header markup, right", blurb = "Pango markup for the header, right side")]
        public string headerr { get; set; default = ""; }

        // Footer parameters
        [Description(nick = "Footer markup, left", blurb = "Pango markup for the footer, left side")]
        public string footerl { get; set; default = ""; }
        [Description(nick = "Footer markup, center", blurb = "Pango markup for the footer, middle")]
        public string footerc { get; set; default = "%p"; }
        [Description(nick = "Footer markup, right", blurb = "Pango markup for the footer, right side")]
        public string footerr { get; set; default = ""; }

        // Font parameters
        [Description(nick = "Font name", blurb = "Font of body text")]
        public string fontname { get; set; default = "Serif"; }
        [Description(nick = "Font size (pt.)", blurb = "Size of body text, in points (72/in.)")]
        public double fontsizeT { get; set; default = 12; }

        // Paragraph parameters
        [Description(nick = "Text alignment", blurb = "Normal paragraph alignment (left/center/right)")]
        public Alignment paragraphalign { get; set; default = LEFT; }
        [Description(nick = "Justify text", blurb = "If true, block-justify.  The 'paragraphalign' property controls justification of partial lines.")]
        public bool justify { get; set; default = false; }
        [Description(nick = "Paragraph skip (in.)", blurb = "Space between paragraphs, in inches")]
        public double parskipI { get; set; default = 12.0/72.0; }

        /** Used in process_node_into() */
        private Regex re_newline = null;

        /**
         * Regex for recognizing pfft commands.
         *
         * A code block with the info string `pfft: <command>` is interpreted
         * as a command rather than as a code block.
         */
        private Regex re_command = null;

        /**
         * Regex for placeholders in headers/footers.
         *
         * Currently supported placeholders are:
         * * `%p`: page number
         * * `%%`: a literal percent sign
         */
        private Regex re_hf_placeholder = null;

        // Not a ctor since we create instances through g_object_new() --- see
        // https://gitlab.gnome.org/GNOME/vala/-/issues/650
        construct {
            try {
                re_newline = new Regex("\\R+");
                re_command = new Regex("^pfft:\\s*(\\w+)");
                re_hf_placeholder = new Regex("%(?<which>[p%])(?!\\w)");
                // can't use \b in place of the negative lookahead because
                // \b doesn't match between two non-word chars
            } catch(RegexError e) { // LCOV_EXCL_START
                lerroro(this, "Could not create required regexes --- I can't go on");
                assert(false);  // die horribly --- something is very wrong!
            }                       // LCOV_EXCL_STOP
        }

        /**
         * Write a document to a file.
         * @param filename  The name of the file to write
         * @param doc       The document to write
         * @param sourcefn  The filename of the source that @doc came from.
         * TODO make paper size a parameter
         */
        public void write_document(string filename, Doc doc, string? sourcefn = null)
        throws FileError, My.Error
        {
            source_fn_ = (sourcefn == null) ? "" : sourcefn;

            int rightP = i2p(lmarginI+hsizeI);
            int bottomP = i2p(tmarginI+vsizeI);

            // Set up the drawing space
            var surf = new Cairo.PdfSurface(filename, i2c(paperwidthI), i2c(paperheightI));
            if(surf.status() != Cairo.Status.SUCCESS) {
                throw new Error.WRITER("Could not create surface: " +
                          surf.status().to_string());
            }

            // Prepare to render
            cr_ = new Cairo.Context(surf);
            layout_ = Blocks.new_layout(cr_, fontname, fontsizeT, paragraphalign,
                    justify);                     // Layout for the copy
            bullet_layout_ = Blocks.new_layout(cr_, fontname, fontsizeT);

            pageno_layout_ = Blocks.new_layout(cr_, fontname, fontsizeT); // Layout for page numbers

            cr_.move_to(i2c(lmarginI), i2c(tmarginI));
            // over, down (respectively) from the UL corner

            // Break the text into individually-rendered blocks.
            // Must be done after `layout_` is created.
            var blocks = make_blocks(doc);

#if 0
            // DEBUG - check the type of font
            var pcfm = Pango.CairoFontMap.get_default() as Pango.CairoFontMap;
            if(pcfm != null) {
                var fty = pcfm.get_font_type();
                print("Font type is %d\n", (int)fty);
            }
#endif

            // Render
            pageno_ = 1;
            first_on_page_ = true;
            Blk prev_blk = null;

            linfoo(this, "Beginning rendering");
            foreach(var blk in blocks) {
                if(blk.is_void()) {
                    llogo(blk, "skipping void block");
                    continue;
                }

                ldebugo(blk, "start render");
                while(true) {   // Render this block, which may take more than one pass
                    // Parameters to render() are page-relative
                    if(surf.status() != Cairo.Status.SUCCESS) {
                        lerroro(blk, "Surface status: %s", surf.status().to_string());  // LCOV_EXCL_LINE because I can't force this to happen
                    }

                    // Parskip

                    llogo(blk, "parskip check: %s; %s; %s; %s",
                        first_on_page_ ? "first on page" : "not first on page",
                        prev_blk != null ? "has prev blk" : "no prev blk",
                        blk.parskip_category.to_string(),
                        (prev_blk != null && prev_blk.parskip_category != blk.parskip_category) ?
                        "differs from prevblk category" : "no prev, or same as prev category"
                    );

                    if(!first_on_page_ && prev_blk != null &&
                        ( blk.parskip_category == COPY ||
                        blk.parskip_category == HEADER ||
                        prev_blk.parskip_category != blk.parskip_category)
                    ) {
                        llogo(blk, "Applying parskip %f in.", parskipI);
                        cr_.rel_move_to(0, i2c(parskipI));
                    }

                    // Render

                    var ok = blk.render(cr_, rightP, bottomP);
                    if(ok == COMPLETE || ok == PARTIAL) {
                        first_on_page_ = false;
                    }

                    if(ok == RenderResult.COMPLETE) {
                        break;  // Move on to the next block
                    } else if(ok == RenderResult.ERROR) {
                        lerroro(blk, "render returned %s", ok.to_string());
                        assert(false);  // TODO improve this
                    }

                    // We got PARTIAL or NONE, so we need to start a new page.
                    eject_page();
                }
                ldebugo(blk, "end render");

                prev_blk = blk;
            } // foreack blk

            // We only eject in the loop above when a block demands it.
            // Therefore, there should always be a page to eject here,
            // even if there were no blocks.
            eject_page();

            // Save the PDF
            surf.finish();
            if(surf.status() != Cairo.Status.SUCCESS) {
                // LCOV_EXCL_START because I can't force this to happen
                throw new Error.WRITER("Could not save PDF: " +
                          surf.status().to_string());
                // LCOV_EXCL_STOP
            }
            linfoo(this, "Done rendering");

        } // write_document()

        /** Finish the current page and write it out */
        void eject_page()
        {
            linfoo(this, "Finalizing page %d", pageno_);
            render_headers_footers();
            cr_.show_page();

            // Start the next page
            ++pageno_;
            first_on_page_ = true;
            cr_.new_path();
            cr_.move_to(i2c(lmarginI), i2c(tmarginI));
            double leftC, topC;
            cr_.get_current_point(out leftC, out topC);
            linfoo(this, "Starting page %d at (%f,%f) %s l %f t %f", pageno_,
                c2i(leftC), c2i(topC), cr_.has_current_point() ? "has pt" : "no pt",
                lmarginI, tmarginI);

        } // eject_page()

        /** render the page header(s)/footer(s) on the page we just finished */
        private void render_headers_footers()
        {
            int hsizeP = i2p(hsizeI);

            double headeryI = tmarginI-headerskipI;
            render_one_hf("headerL", headerl, hsizeP, LEFT, lmarginI, headeryI);
            render_one_hf("headerC", headerc, hsizeP, CENTER, lmarginI, headeryI);
            render_one_hf("headerR", headerr, hsizeP, RIGHT, lmarginI, headeryI);

            double footeryI = tmarginI+vsizeI+footerskipI;
            render_one_hf("footerL", footerl, hsizeP, LEFT, lmarginI, footeryI);
            render_one_hf("footerC", footerc, hsizeP, CENTER, lmarginI, footeryI);
            render_one_hf("footerR", footerr, hsizeP, RIGHT, lmarginI, footeryI);
        }

        /** Replace "%p" and other placeholders in header/footer text */
        private bool replace_hf_placeholders (string ident, MatchInfo match_info, StringBuilder result)
        {
            bool ok = false;
            ltraceo(this, "HF %s: checking placeholders", ident);

            do { // once
                if(match_info.get_match_count() == 0) {
                    break;
                }

                string which = match_info.fetch_named("which");
                llogo(this, "placeholder %s", which != null ? which : "<null>");
                if(which == null) {
                    break;
                }

                switch(which) {
                case "p":
                    result.append(pageno_.to_string());
                    ok = true;
                    break;
                case "%":
                    result.append("%");
                    ok = true;
                    break;
                default:
                    break;
                }
            } while(false);

            if(!ok) {
                string fullmatch = match_info.fetch(0);
                if(fullmatch == null) {
                    fullmatch = "<null>";
                }
                lwarningo(this, @"I don't understand the placeholder '$fullmatch'");
            }

            return false;   // keep going
        }

        /**
         * Render one header or footer.
         *
         * @param ident     Which header/footer.  Only used for log messages.
         * @param markup    The Pango markup to render
         * @param widthP    The width to use for the layout
         * @param align     The alignment to use for the layout
         * @param leftI     Where to render (X) with respect to the page
         * @param topI      Where to render (Y) with respect to the page
         */
        private void render_one_hf(string ident, string markup, int widthP,
            Pango.Alignment align, double leftI,
            double topI)
        {
            if(markup == "") {
                ltraceo(this, "HF %s: Skipping --- no markup", ident);
                return;
            }
            ltraceo(this, "HF %s: Processing markup -%s-", ident, markup);

            string m2;  // modified markup post placeholder processing
            try {
                m2 = re_hf_placeholder.replace_eval(markup, -1, 0, 0,
                        (m, s)=>{ return replace_hf_placeholders(ident, m, s); });
            } catch(RegexError e) {
                lwarningo(this, "Got regex error: %s", e.message);
                m2 = markup;
            }

            // By default, make the text smaller.  The user can override this
            // with an express `<span>`.
            m2 = @"<span size=\"small\">$m2</span>";

            ltraceo(this, "HF %s: Rendering", ident);
            pageno_layout_.set_width(widthP);
            pageno_layout_.set_alignment(align);
            pageno_layout_.set_markup(m2, -1);
            cr_.move_to(i2c(leftI), i2c(topI));
            Pango.cairo_show_layout(cr_, pageno_layout_);
            ltraceo(this, "HF %s: Done", ident);
        }

        ///////////////////////////////////////////////////////////////////
        // Generate blocks of markup from a Doc.
        // The methods in this section assume cr_ and layout_ members are valid

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
        private IndentType get_indent_type_for_level(uint level, bool is_bullet)
        {
            unowned IndentType[] defns = is_bullet ? indentation_levels_bullets :
                indentation_levels_numbers;
            level %= defns.length;  // Cycle through the definitions
            return defns[level];
        }

        /**
         * The rendering state.
         *
         * TODO move the per-level items into a helper class, and add a
         * current_level accessor.
         */
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

            /**
             * Left margins of content, in Pango units.
             *
             * The left margin of content in each level, or 0 if none.
             */
            public int[] content_lmarginsP = {};

            /**
             * Left margins of bullets/numbers, in Pango units.
             *
             * The left margin of the bullet/number in each level, or 0 if none.
             */
            public int[] bullet_lmarginsP = {};

            public State clone() {
                var retval = new State();
                retval.obeylines = obeylines;
                retval.levels = levels;     // duplicates the array
                retval.last_numbers = last_numbers;
                retval.content_lmarginsP = content_lmarginsP;
                retval.bullet_lmarginsP = bullet_lmarginsP;
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
            var first_blk = new ParaBlk(layout_);

            // Fill the list
            var last_blk = process_node_into(doc.root, el, (owned)first_blk, retval, state);
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
            llogo(blk, "commit: adding blk with markup <%s> and post-markup <%s>",
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
            string cmd = "";  // a processing command (```pfft:foo ...```), or ""
            bool trim_trailing_whitespace = false;
            StringBuilder sb = new StringBuilder();

            var state = state_in;

            ldebugo(node, "process_node_into: %s%s = '%s'",
                string.nfill(node.depth()*4, ' '), el.ty.to_string(),
                text_markup);

            // Reminder: parameters to Blk instances are relative to the
            // left margin.
            switch(el.ty) {
            case ROOT:
                // Nothing to do
                break;

            // --- divs -----------------------------------------
            case BLOCK_HEADER:
                commit(blk, retval);
                blk = new ParaBlk(layout_, true);
                sb.append_printf("<span %s>%s",
                    header_attributes[el.header_level],
                    text_markup);
                blk.post_markup = "</span>";
                complete = true;
                break;

            case BLOCK_COPY:
            case BLOCK_SPECIAL: // TODO treat BLOCK_SPECIAL differently
                blk.markup += text_markup;
                // Do not create a new blk here since there may be other
                // nodes that have yet to contribute to blk.
                complete = true;
                break;

            case BLOCK_QUOTE:
                commit(blk, retval);
                int marginP = i2p(0.5); // text is indented 0.5" past marker
                if(state.levels.length > 0) {
                    var lidx = state.levels.length - 1;
                    marginP += state.content_lmarginsP[lidx];
                }
                blk = new QuoteBlk(layout_, marginP);
                sb.append(text_markup);
                complete = true;
                break;

            case BLOCK_BULLET_LIST:     // Get the next indentation level
            case BLOCK_NUMBER_LIST:     // Likewise
                complete = true;

                // Copy the state so any changes are localized to this block and
                // any children.
                state = state.clone();

                // Add the indentation level
                var is_bullet = el.ty == BLOCK_BULLET_LIST;
                var indent_type = get_indent_type_for_level(state.levels.length,
                        is_bullet);
                state.levels += indent_type;
                var lidx = state.levels.length - 1;
                state.last_numbers += 0;

                // TODO? change this?
                int marginC = is_bullet ? 18 : 36;
                state.content_lmarginsP += c2p((lidx+1)*marginC);
                state.bullet_lmarginsP += c2p(lidx*marginC);
                llogo(blk, "Now in lidx %d with indent type %s, bullet lmarg %f, content lmarg %f",
                    lidx, indent_type.to_string(), p2i(state.bullet_lmarginsP[lidx]),
                    p2i(state.content_lmarginsP[lidx]));
                break;

            case BLOCK_LIST_ITEM:
                commit(blk, retval);
                var lidx = state.levels.length - 1;
                state.last_numbers[lidx]++;

                blk = new BulletBlk(layout_, bullet_layout_, "%s%s".printf(
                            state.levels[lidx].render(state.last_numbers[lidx]),
                            state.levels[lidx].is_bullet() ? "" : "."
                        ),
                        state.bullet_lmarginsP[lidx],
                        state.content_lmarginsP[lidx]
                );
                sb.append(text_markup);

                complete = true;
                break;

            case BLOCK_HR:
                commit(blk, retval);
                blk = new HRBlk(layout_, 0);
                complete = true;
                // TODO figure out how to handle rules inside indented lists
                break;

            case BLOCK_CODE:
                commit(blk, retval);

                int marginP = 0;
                if(state.levels.length > 0) {
                    var lidx = state.levels.length - 1;
                    marginP = state.content_lmarginsP[lidx];
                }
                blk = new CodeBlk(layout_, marginP, i2p(0.25));

                state = state.clone();

                MatchInfo matches;
                if(re_command.match(el.info_string, 0, out matches)) {
                    // Not actually a code block --- a directive to pfft.
                    cmd = matches.fetch(1);
                    state.obeylines = false;
                    sb.append_printf("%s ", text_markup);
                    // Let the rest of the function run to collect the text
                } else {    // a normal code block
                    state.obeylines = true;
                    sb.append_printf("<tt>%s%s", text_markup,
                        text_markup.length > 0 ? " " : "");
                    // NOTE: does a code block ever have text of its own?
                    blk.post_markup = "</tt>" + blk.post_markup;
                }
                trim_trailing_whitespace = true;    // trim trailing \n, if any
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
            case SPAN_IMAGE:
                sb.append(OBJ_REPL_CHAR());
                var shape = new Shape.Image.from_href(el.href, source_fn_,
                        el.info_string);
                blk.add_shape(shape);
                break;

            // --------------------------------------------------
            default:
                lwarningo(el, "Unknown elem type %s", el.ty.to_string());
                break;
            }

            blk.markup += sb.str;
            lmemdumpo(blk, "Markup after appending sb", blk.markup, blk.markup.length);

            // process children
            for(uint i = 0; i < node.n_children(); ++i) {
                unowned GLib.Node<Elem> child = node.nth_child(i);
                var newblk = process_node_into(child, child.data, (owned)blk,
                        retval, state);
                blk = newblk;
            }

            blk.markup += post_children_markup;
            lmemdumpo(blk, "Markup after appending post_children_markup",
                blk.markup, blk.markup.length);

            // Join lines
            if(!state.obeylines) {
                try {
                    blk.markup = re_newline.replace(blk.markup, -1, 0, " ");
                } catch(RegexError e) {
                    // ignore regex errors
                }
            }

            if(trim_trailing_whitespace) {
                blk.markup._chomp();
            }

            // Respond to commands from special blocks
            switch(cmd) {
            case "":
                // not a command
                break;

            case INFOSTR_NOP:   // Drop the block
                blk = new ParaBlk(layout_);
                complete = true;
                break;

            default:
                lwarningo(this, "Ignoring unknown command '%s'", cmd);
                break;
            }

            if(complete) {
                // lmemdumpo(blk, "Block markup", blk.markup, blk.markup.length);
                commit(blk, retval);
                blk = new ParaBlk(layout_);
            }

            return (owned)blk;
        }         // process_div_into

    }         // class PangoMarkupWriter
}         // My

// Thanks to the following for information:
// - https://wiki.gnome.org/Projects/Vala/PangoCairoSample
//   by Dov Grobgeld <dov.grobgeld@gmail.com>
// - https://gist.github.com/bert/262331/9dcb6a35460f2eb84571164bf84cbb2a6fc8d367
//   by Bert Timmerman
// - https://developer.gnome.org/pygtk/stable/pango-markup-language.html
// - https://developer.gnome.org/pango/stable/pango-Markup.html
