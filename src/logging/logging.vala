// core/logging.vala - Logging front-end.
// Part of pfft, https://github.com/cxw42/pfft
//
// NOTE: If you put any executable code in this file (as opposed to
// declarations), adjust Makefile.am's treatment of the generated logging.c.
// As of writing, logging.c has no content we need.
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: LGPL-2.0-or-later

// NOTE: can't apply cheader_filename to My directly, or it messes up the
// cheaders for other parts of My.
namespace My {
    namespace Log {
        public extern Gst.DebugCategory? category;

        // === Logging functions ===
        // These are all defined in gst/gst.h.  However, we include them
        // from logging-c.h.  That file defines the default debug
        // category, then pulls in gst.h.

        [CCode(cname="GST_ERROR", cheader_filename = "logging-c.h")]
        [PrintfFormat]
        public extern void lerror (string format, ...);

        [CCode(cname="GST_WARNING", cheader_filename = "logging-c.h")]
        [PrintfFormat]
        public extern void lwarning (string format, ...);

        [CCode(cname="GST_FIXME", cheader_filename = "logging-c.h")]
        [PrintfFormat]
        public extern void lfixme (string format, ...);

        [CCode(cname="GST_INFO", cheader_filename = "logging-c.h")]
        [PrintfFormat]
        public extern void linfo (string format, ...);

        [CCode(cname="GST_DEBUG", cheader_filename = "logging-c.h")]
        [PrintfFormat]
        public extern void ldebug (string format, ...);

        [CCode(cname="GST_LOG", cheader_filename = "logging-c.h")]
        [PrintfFormat]
        public extern void llog (string format, ...);

        [CCode(cname="GST_TRACE", cheader_filename = "logging-c.h")]
        [PrintfFormat]
        public extern void ltrace (string format, ...);

        [CCode(cname="GST_MEMDUMP", cheader_filename = "logging-c.h")]
        public extern void lmemdump (string message, string data, int length);

        [CCode(cname="GST_ERROR_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        [PrintfFormat]
        public extern void lerroro<T>(T obj, string format, ...);

        [CCode(cname="GST_WARNING_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        [PrintfFormat]
        public extern void lwarningo<T>(T obj, string format, ...);

        [CCode(cname="GST_FIXME_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        [PrintfFormat]
        public extern void lfixmeo<T>(T obj, string format, ...);

        [CCode(cname="GST_INFO_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        [PrintfFormat]
        public extern void linfoo<T>(T obj, string format, ...);

        [CCode(cname="GST_DEBUG_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        [PrintfFormat]
        public extern void ldebugo<T>(T obj, string format, ...);

        [CCode(cname="GST_LOG_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        [PrintfFormat]
        public extern void llogo<T>(T obj, string format, ...);

        [CCode(cname="GST_TRACE_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        [PrintfFormat]
        public extern void ltraceo<T>(T obj, string format, ...);

        [CCode(cname="GST_MEMDUMP_OBJECT", cheader_filename = "logging-c.h", simple_generics = true)]
        public extern void lmemdumpo<T>(T obj, string message, string data, int length);

        /**
         * Initialize the logging subsystem.
         *
         * Call this after Gst.init() and before any of the above logging functions.
         *
         * NOTE: To get Vala filenames and line numbers, you need to pass
         * the "-g" option to valac.  Otherwise, you will get the filenames and
         * line numbers of the generated C code.
         */
        [CCode (cheader_filename = "logging-c.h")]
        public extern void linit();

        /**
         * Determine whether a log level is enabled for our debug category.
         *
         * This function is expressly meant to guard expensive debug statements,
         * so may cause slowdown when debugging is enabled.
         */
        [CCode (cheader_filename = "logging-c.h")]
        public extern bool lenabled(Gst.DebugLevel level);

    } // Log

    ////////////////////////////////////////////////////////////////////////
    // Misc. LGPL functions

    // These are in src/logging since that's the LGPL part of pfft.

    /**
     * A copy of g_canonicalize_filename, which was added to Glib after
     * Ubuntu Bionic.
     *
     * This doesn't belong in a logging library, but since this is the LGPL
     * part of pfft, here it is!
     */
    [CCode (cheader_filename = "logging-c.h")]
    public extern string canonicalize_filename (string filename,
        string? relative_to = null);

    /**
     * A copy of g_assert_cmpfloat(), which was added to GLib after Bionic.
     */
    [CCode (cheader_filename = "logging-c.h")]
    public extern void assert_cmpfloat(double n1, string cmp, double n2);

    /**
     * A copy of g_assert_cmpfloat_with_epsilon(), which was added to GLib
     * after Bionic.
     */
    [CCode (cheader_filename = "logging-c.h")]
    public extern void assert_cmpfloat_with_epsilon(double n1, double n2, double epsilon);

    /**
     * g_assert_cmpfloat_with_epsilon(), but always using double.EPSILON.
     */
    [CCode (cheader_filename = "logging-c.h")]
    public extern void assert_double_close(double n1, double n2);

    /** Comparison operators for use with assert_cmpfloat() and friends */
    namespace Cmp {
        [CCode (cname="==")]
        public extern const string EQ;
        [CCode (cname="!=")]
        public extern const string NE;
        [CCode (cname="<")]
        public extern const string LT;
        [CCode (cname="<=")]
        public extern const string LE;
        [CCode (cname=">")]
        public extern const string GT;
        [CCode (cname=">=")]
        public extern const string GE;
    } // Cmp

} // My
