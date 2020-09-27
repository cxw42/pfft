// src/core/template.vala - part of pfft, https://github.com/cxw42/pfft
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My.Log;

namespace My {

    /** Text alignment */
    public enum Alignment {
        /** Left-justified */
        LEFT,
        /** Centered */
        CENTER,
        /** Right-justified */
        RIGHT,
    }

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

        // Page parameters (unit suffixes: Inches, Cairo, Pango, poinT)
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

        // Font parameters
        [Description(nick = "Font size (pt.)", blurb = "Size of body text, in points (72/in.)")]
        public double fontsizeT { get; set; default = 12; }

        // Paragraph parameters
        [Description(nick = "Text alignment", blurb = "Normal paragraph alignment (left/center/right)")]
        public Alignment paragraphalign { get; set; default = LEFT; }
        [Description(nick = "Justify text", blurb = "If true, block-justify.  The 'paragraphalign' property controls justification of partial lines.")]
        public bool justify { get; set; default = false; }

        // Private properties --- leading "P" marks them to be ignored by
        // other parts of pfft.

        /** Temporary holder for use with set_from_file() */
        [Description(nick = "Private use")]
        public double PtempI { get; set; }

        // --- Key parsers -----------------------------

        // There is a fair amount of duplication here because the accessors
        // in KeyFile change with type.  TODO refactor to reduce duplication
        // (if possible).

        /**
         * A function that can parse a string into a Value.
         *
         * @param section   The keyfile section the string came from
         * @param key       The keyfile key the string came from
         * @param text      The string read from the keyfile
         * @param val       The value to fill in.  It already has the property's
         *                  type when this is called.
         *
         * @return          True on success; false otherwise.
         */
        private delegate bool ValueParser(string section, string key,
            string text, ref Value val);

        /**
         * A ValueParser that uses deserialize_value().
         */
        private bool default_value_parser(string section, string key,
            string text, ref Value val)
        {
            if(!deserialize_value(ref val, text)) {
                lerroro(this, "Could not understand key [%s]%s as a %s",
                    section, key, val.type().to_string());
                return false;
            }
            return true;
        }

        /**
         * A ValueParser for dimensions.
         *
         * Only works on doubles.
         */
        private bool dimension(string section, string key,
            string text, ref Value val)
        {
            if(val.type() != typeof(double)) { // LCOV_EXCL_START - unreachable unless I made a mistake
                lfixmeo(this, "Trying to call parse_dimension() on a non-double");
                return false;
            }   // LCOV_EXCL_STOP

            double newval;
            try {
                newval = Units.parsedim(text);
            } catch(My.Error e) {
                lerroro(this, "Could not understand the dimension for [%s]%s",
                    section, key);
                return false;
            }

            val.set_double(newval);
            return true;
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

        /**
         * Deserialize a parameter from a (possibly-localized) string in the keyfile.
         *
         * Ignores keyfile errors; missing keys are not fatal.
         *
         * This function reads the locale string for the given key,
         * then attempts to deserialize it using deserialize_value().
         *
         * @param property  The property in this class to load.  The type of
         *                  this property is used as the type to deserialize.
         * @param section   The keyfile section to read from
         * @param key       The keyfile key to load from
         * @param parse     A function that can parse a value
         */
        private void set_from_file(string property, string section, string key,
            ValueParser parse = default_value_parser)
        {
            string text;

            ObjectClass ocl = (ObjectClass) get_type().class_ref();
            var prop_meta = ocl.find_property(property);
            if(prop_meta == null) { // LCOV_EXCL_START - unreachable unless I made a mistake
                lfixmeo(this, "Could not find property %s", property);
                return;
            }   // LCOV_EXCL_STOP
            var wrapped = Value(prop_meta.value_type);

            try {
                text = data.get_locale_string(section, key);
            } catch(KeyFileError e) {
                return;
            }

            if(!parse(section, key, text, ref wrapped)) {
                return;
            }

            set_property(property, wrapped);
        }

        /** Throw if the given group has both keys */
        void error_if_both_keys(string section, string k1, string k2) throws KeyFileError
        {
            if(data.has_key(section, k1) && data.has_key(section, k2)) {
                throw new KeyFileError.PARSE(@"Section $section has keys $k1 and $k2, and I don't know which you want to use.  Please remove one of them.");
            }
        }

        // --- Constructors ----------------------------

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
            set_from_file("PtempI", "pfft", "version", dimension);
            if(PtempI != 1) {  // float equality OK here
                throw new KeyFileError.PARSE("I don't know which file version this is");
            }

            // Load whatever data we have
            if(data.has_group("page")) {
                set_from_file("paperheightI", "page", "height", dimension);
                ldebugo(this, "paper height %f in", paperheightI);
                set_from_file("paperwidthI", "page", "width", dimension);
                ldebugo(this, "paper width %f in", paperwidthI);
            } // page

            if(data.has_group("margin")) {
                set_from_file("headerskipI", "margin", "header", dimension);
                ldebugo(this, "header skip %f in", headerskipI);
                set_from_file("footerskipI", "margin", "footer", dimension);
                ldebugo(this, "footer skip %f in", footerskipI);

                set_from_file("tmarginI", "margin", "top", dimension);
                set_from_file("lmarginI", "margin", "left", dimension);

                // Margin->hsize/vsize
                PtempI = -1;
                set_from_file("PtempI", "margin", "bottom", dimension);
                if(PtempI>=0) {
                    vsizeI = paperheightI - tmarginI - PtempI;
                }
                ldebugo(this, "vsize %f in", vsizeI);

                PtempI = -1;
                set_from_file("PtempI", "margin", "right", dimension);
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

            if(data.has_group("font")) {
                set_from_file("fontsizeT", "font", "size");
                ldebugo(this, "font size %f pt", fontsizeT);
            }

            if(data.has_group("paragraph")) {
                set_from_file("paragraphalign", "paragraph", "align");
                set_from_file("justify", "paragraph", "justify");
            }

            ldebugo(this, "Done processing template file %s", filename);
        } // Template.from_file()

        // --- Using templates -------------------------

        /**
         * Copy property values into an object.
         *
         * For each non-private property that exists both in this template and
         * the target instance, the value will be copied from the target to the
         * new instance.
         *
         * @param target        The instance to update.  Modified in place.
         */
        public void set_props_on(Object target)
        {
            // property accessor for the instance we are creating
            ObjectClass ocl = (ObjectClass) target.get_type().class_ref ();

            // property accessor for the template
            ObjectClass tocl = (ObjectClass) this.get_type().class_ref ();

            // Set properties from the template
            foreach(var tprop in tocl.list_properties()) {
                string propname = tprop.get_name();
                ldebugo(target, "Trying template property %s", propname);
                var prop = ocl.find_property(propname);
                if(prop == null || propname[0] == 'P' || prop.value_type != tprop.value_type) {
                    ldebugo(target, "  --- skipping");
                    continue;
                }

                Value v = Value(prop.value_type);
                this.get_property(propname, ref v);
                target.set_property(propname, v);
                linfoo(target, "Set property %s from template to %s",
                    propname, Gst.Value.serialize(v));
            }
        } // set_props_on()

    } // class Template

} // namespace My
