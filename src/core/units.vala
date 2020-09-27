// src/core/units.vala - part of pfft
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {
    namespace Units {
        // --- Regexes ---

        /** Regex to match the strings parse_dimension() understands */
        private static Regex re_dim = null;

        /**
         * Map from units to fractions of an inch.
         *
         * Note: we are accepting floating-point error here.
         */
        private Gee.HashMap<string, double?> unit_per_in = null;

        // --- Routines ---

        /**
         * Parse text as a dimension (length).
         *
         * This function parses a dimension in textual form and returns its value
         * in inches (because the lead developer lives in a country that uses
         * inches ;) ).
         *
         * The allowable dimensions are taken from CSS and TeX.  I am using
         * 72 ppi, so `1 pt` here is what TeX calls `1 bp`, and `1 tpt` ("TeX
         * PoinT") here is what TeX calls `1 pt`.  The `sp` is still defined
         * as in TeX: 72.27*65536 per inch.
         *
         * The `px` is always 1/96 in.
         */
        public static double parsedim(string text)
        throws Error
        {
            if(re_dim == null) {    // init regex
                try {
                    // Note: possessive quantifiers (`*+`) to prevent
                    // way too much backtracking.
                    re_dim = new Regex(
                        "^\\h*+" +
                        "(?<quantity>" +
                        // The next line is from Perl's Regexp::Common ---
                        // see comments at end of file.
                        "(?:(?:[-+]?)(?:(?=[.]?[0123456789])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[Ee])(?:(?:[-+]?)(?:[0123456789]+))|))" +
                        ")\\h*+" +
                        "(?<unit>(?:(?:cc|cm|dd|ft|in|m|mm|pc|pt|px|Q|sp|tpt)\\b)?)" +
                        "\\h*$");
                } catch(RegexError e) { // LCOV_EXCL_START
                    printerr("Could not create required regex for dimensions --- I can't go on\n");
                    assert(false);  // die horribly --- something is very wrong!
                }                       // LCOV_EXCL_STOP

                unit_per_in = new Gee.HashMap<string,double?>();

                // per the TeXbook, with 1996 corrections, p. 57
                double tpt = 72.27;
                double dd = tpt /* tpt/in */ * 1157/1238 /* dd/tpt */;

                unit_per_in.set("cc", dd / 12 /*dd/cc*/);
                unit_per_in.set("cm", 2.54);
                unit_per_in.set("dd", dd);
                unit_per_in.set("ft", 1.0/12);
                unit_per_in.set("in", 1);
                unit_per_in.set("m", 1.0/39.37);
                unit_per_in.set("mm", 25.4);
                unit_per_in.set("pc", 6);
                unit_per_in.set("pt", 72);
                unit_per_in.set("px", 96);
                unit_per_in.set("Q", 25.4*4);    // quarter of a mm
                unit_per_in.set("sp", tpt*65536);
                unit_per_in.set("tpt", tpt);
            }

            MatchInfo matches;
            if(!re_dim.match(text, 0, out matches)) {
                Log.lmemdump("Text that could not be parsed", text, text.length);
                throw new Error.INVALID_CONVERSION("Could not understand the provided text");
            }

            string squantity = matches.fetch_named("quantity");
            string sunit = matches.fetch_named("unit");

            if(squantity == null || sunit == null) {    // LCOV_EXCL_START
                Log.lmemdump("Text that matched, but both pieces weren't present",
                    text, text.length);
                throw new Error.INVALID_CONVERSION("Could not find a quantity and a unit in the provided text");
            }   // LCOV_EXCL_STOP

            if(sunit == "") {    // default unit = inches
                sunit = "in";
            }

            double quantity;

            if(!double.try_parse(squantity, out quantity)) {
                // LCOV_EXCL_START --- I'm not sure this is possible given the regex
                Log.lmemdump("Quantity that couldn't be understood as a double",
                    squantity, squantity.length);
                throw new Error.INVALID_CONVERSION("Could not understand the provided quantity");
            } // LCOV_EXCL_STOP

            if(!unit_per_in.has_key(sunit)) {
                // LCOV_EXCL_START --- this should not be possible given the
                // regex.  I am leaving this in the code in case I later change
                // the regex but forget to update unit_per_in.
                Log.lmemdump("Unit that I don't know about", sunit, sunit.length);
                throw new Error.INVALID_CONVERSION("I don't understand the provided unit");
            } // LCOV_EXCL_STOP

            double units_per_in = unit_per_in.get(sunit);
            quantity /= units_per_in;

            return quantity;
        }
    } // Units
} // My

/*
 * Regexp for floating-point values is the output of
 *      perl -MRegexp::Common -E 'say $RE{num}{real}'
 * which is found at <https://metacpan.org/source/ABIGAIL/Regexp-Common-2017060201/lib/Regexp/Common/number.pm>.
 * The license for Regexp::Common is as follows:
 *
 *      This software is Copyright (c) 2001 - 2017, Damian Conway and Abigail.
 *      All rights reserved.
 *
 *      Redistribution and use in source and binary forms, with or without
 *      modification, are permitted provided that the following conditions
 *      are met:
 *
 *          * Redistributions of source code must retain the above copyright
 *            notice, this list of conditions and the following disclaimer.
 *          * Redistributions in binary form must reproduce the above
 *            copyright notice, this list of conditions and the following disclaimer
 *            in the documentation and/or other materials provided with the
 *            distribution.
 *          * The names of its contributors may not be used to endorse or promote
 *            products derived from this software without specific prior
 *            written permission.
 *
 *      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *      A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *      TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *      LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *      NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
