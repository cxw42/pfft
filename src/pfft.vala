// pfft.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {
    /**
     * Main application class for pfft
     */
    public class App {
        /** Whether to print the version info */
        private static bool opt_version = false;

        /**
         * Command-line options
         *
         * Thanks for syntax to the sample at
         * https://valadoc.org/glib-2.0/GLib.OptionEntry.html
         */
        private const GLib.OptionEntry[] options = {
            // --version
            { "version", 0, 0, OptionArg.NONE, ref opt_version, "Display version number", null },

            /*
               // --directory FIlENAME || -o FILENAME
               { "directory", 'o', 0, OptionArg.FILENAME, ref directory, "Output directory", "DIRECTORY" },
               // [--vapidir FILENAME]*
               { "importdir", 0, 0, OptionArg.FILENAME_ARRAY, ref importdirs, "Look for external documentation in DIRECTORY", "DIRECTORY..." },

               // --driver
               { "driver", 0, 0, OptionArg.STRING, ref driver, "Use the given driver", "DRIVER" },
               // [--import STRING]*
               { "import", 0, 0, OptionArg.STRING_ARRAY, ref import_packages, "Include binding for PACKAGE", "PACKAGE..." },

               // --double DOUBLE
               { "double", 0, 0, OptionArg.DOUBLE, ref numd, "double value", "DOUBLE" },
               // --int64 INT64
               { "int64", 0, 0, OptionArg.INT64, ref numi64, "int64 value", "INT64" },
               // --int INT
               { "int", 0, 0, OptionArg.INT, ref numi, "int value", "INT" },
             */

            // list terminator
            { null }
        };

        /**
         * print a friendly message
         */
        public static int main(string[] args)
        {
            try {
                var opt_context = new OptionContext ("- %s".printf(PACKAGE_NAME));
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (options, null);
                opt_context.parse (ref args);
            } catch (OptionError e) {
                printerr ("error: %s\n", e.message);
                printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
                return 1;
            }

            if (opt_version) {
                stdout.printf("%s\nVisit %s for more information\n", PACKAGE_STRING, PACKAGE_URL);
                return 0;
            }

            return 0;
        }
    }
} // My
