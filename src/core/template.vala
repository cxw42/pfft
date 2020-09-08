// src/core/template.vala - part of pfft, https://github.com/cxw42/pfft
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My.Log;

namespace My {

    /**
     * A document template defining document appearance &c.
     */
    public class Template : Object {
        /**
         * The data.
         *
         * Public for now, until I figure out a better set of accessors.
         */
        public KeyFile data;

        // --- Accessors for the template's contents ---

        // Page parameters (unit suffixes: Inches, Cairo, Pango)
        [Description(nick = "Paper width (in.)", blurb = "Paper width, in inches")]
        public double paperwidthI { get; set; default = 8.5; }
        [Description(nick = "Paper height (in.)", blurb = "Paper height, in inches")]
        public double paperheightI { get; set; default = 11.0; }
        [Description(nick = "Left margin (in.)", blurb = "Left margin, in inches")]

        // Margin parameters
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

        // Private properties --- leading "P" marks them to be ignored by
        // other parts of pfft.

        /** Temporary holder for use with set_from_file_double(). */
        [Description(nick = "Private use")]
        public double PtempI { get; set; }

        // --- Routines --------------------------------

        /**
         * Set a double parameter from the keyfile.
         *
         * Ignore keyfile errors; missing keys are not fatal.
         */
        private void set_from_file_double(string property, string section, string key)
        {
            double fromfile;
            try {
                fromfile = data.get_double(section, key);
            } catch(KeyFileError e) {
                return;
            }

            var wrapped = Value(typeof(double));
            wrapped.set_double(fromfile);
            set_property(property, wrapped);
        }

        /**
         * Set a (possibly-localized) string parameter from the keyfile.
         * @param property      The name of the property of `this` to set
         * @param section       The section to look in
         * @param keys          The keys to try, in order.  Processing stops
         *                      as soon as one key succeeds.
         * @return the index in keys that succeeded, or -1 if none succeeded.
         *
         * Ignore keyfile errors; missing keys are not fatal.
         */
        private int set_from_file_string(string property, string section,
            string[] keys)
        {
            int idx = -1;
            int retval = -1;

            foreach(string key in keys) {
                ++idx;
                string fromfile;
                try {
                    fromfile = data.get_locale_string(section, key);    // default locale
                } catch(KeyFileError e) {
                    continue;
                }

                var wrapped = Value(typeof(string));
                wrapped.set_string(fromfile);
                set_property(property, wrapped);
                retval = idx;
                break;
            }
            return retval;
        } // set_from_file_string()

        /** Throw if the given group has both keys */
        void error_if_both_keys(string section, string k1, string k2) throws KeyFileError
        {
            if(data.has_key(section, k1) && data.has_key(section, k2)) {
                throw new KeyFileError.PARSE(@"Section $section has keys $k1 and $k2, and I don't know which you want to use.  Please remove one of them.");
            }
        }

        /** Default ctor --- leave all the properties at their default values. */
        public Template()
        {
        }

        /** Load a template file */
        public Template.from_file(string filename)
        throws KeyFileError, FileError
        {
            data = new KeyFile();
            data.load_from_file(filename, NONE);    // throws on error

            // The only required key is pfft.version.
            if(!data.has_group("pfft")) {
                throw new KeyFileError.GROUP_NOT_FOUND("Invalid file: 'pfft' group missing");
            } // pfft

            ldebugo(this, "Loaded key file %s", filename);
            PtempI = -1;
            set_from_file_double("PtempI", "pfft", "version");
            if(PtempI != 1) {  // float equality OK here
                throw new KeyFileError.PARSE("I don't know which file version this is");
            }

            // Load whatever data we have
            if(data.has_group("page")) {
                set_from_file_double("paperheightI", "page", "height");
                ldebugo(this, "paper height %f in", paperheightI);
                set_from_file_double("paperwidthI", "page", "width");
                ldebugo(this, "paper width %f in", paperwidthI);
            } // page

            if(data.has_group("margin")) {
                set_from_file_double("headerskipI", "margin", "header");
                ldebugo(this, "header skip %f in", headerskipI);
                set_from_file_double("footerskipI", "margin", "footer");
                ldebugo(this, "footer skip %f in", footerskipI);

                set_from_file_double("tmarginI", "margin", "top");
                set_from_file_double("lmarginI", "margin", "left");

                // Margin->hsize/vsize
                PtempI = -1;
                set_from_file_double("PtempI", "margin", "bottom");
                if(PtempI>=0) {
                    vsizeI = paperheightI - tmarginI - PtempI;
                }
                ldebugo(this, "vsize %f in", vsizeI);

                PtempI = -1;
                set_from_file_double("PtempI", "margin", "right");
                if(PtempI>=0) {
                    hsizeI = paperwidthI - lmarginI - PtempI;
                }
                ldebugo(this, "hsize %f in", hsizeI);
            } // margin

            if(data.has_group("header")) {
                error_if_both_keys("header", "left", "leftmarkup");
                error_if_both_keys("header", "center", "centermarkup");
                error_if_both_keys("header", "right", "rightmarkup");

                if(1 == set_from_file_string("headerl", "header", {"leftmarkup", "left"})) {
                    headerl = Markup.escape_text(headerl);
                }
                if(1 == set_from_file_string("headerc", "header", {"centermarkup", "center"})) {
                    headerc = Markup.escape_text(headerc);
                }
                if(1 == set_from_file_string("headerr", "header", {"rightmarkup", "right"})) {
                    headerr = Markup.escape_text(headerr);
                }
            } // header

            if(data.has_group("footer")) {
                error_if_both_keys("footer", "left", "leftmarkup");
                error_if_both_keys("footer", "center", "centermarkup");
                error_if_both_keys("footer", "right", "rightmarkup");

                if(1 == set_from_file_string("footerl", "footer", {"leftmarkup", "left"})) {
                    footerl = Markup.escape_text(footerl);
                }
                if(1 == set_from_file_string("footerc", "footer", {"centermarkup", "center"})) {
                    footerc = Markup.escape_text(footerc);
                }
                if(1 == set_from_file_string("footerr", "footer", {"rightmarkup", "right"})) {
                    footerr = Markup.escape_text(footerr);
                }
            } // footer

            ldebugo(this, "Done processing template file %s", filename);
        } // Template.from_file()

    } // class Template

}
