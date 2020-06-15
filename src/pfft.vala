// pfft.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {
    /**
     * Main application class for pfft
     */
    public class App {
        /** Whether to print the version info */
        private bool opt_version = false;

        /**
         * Verbosity.
         *
         * Static because that's much simpler than instance-specific
         * for callback options.
         */
        private static int opt_verbose = 0;

        /**
         * Input filename(s).
         *
         * In the system filename encoding.
         */
        private string[]? opt_infns;

        /**
         * Where to output.
         *
         * In the system filename encoding.  If not given, run() will
         * auto-generate the output name.
         */
        private string opt_outfn = "";

        /**
         * Make command-line option descriptors
         *
         * Thanks for syntax to the sample at
         * https://valadoc.org/glib-2.0/GLib.OptionEntry.html .
         * This is in a function so that it can be used per-instance.
         */
        private GLib.OptionEntry[] get_options()
        {
            OptionArgFunc cb_verbose = () => { ++opt_verbose; return true; };
            return {
                       // --version
                       { "version", 'V', 0, OptionArg.NONE, &opt_version, "Display version number", null },
                       // --verbose
                       { "verbose", 'v', OptionFlags.NO_ARG, OptionArg.CALLBACK,
                         (void *)cb_verbose, "Verbosity (can be given multiple times)", null },

                       // --output FIlENAME || -o FILENAME
                       { "output", 'o', 0, OptionArg.FILENAME, &opt_outfn, "Output filename (provided only one input filename is given)", "FILENAME" },

                       // FILENAME* (non-option arg(s))
                       { OPTION_REMAINING, 0, 0, OptionArg.FILENAME_ARRAY, &opt_infns, "Filename(s) to process", "FILENAME..." },

                       /*
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
        }

        /**
         * print a friendly message
         */
        public int run(string[] args)
        {
            Intl.setlocale (LocaleCategory.ALL, "");    // init locale from environment

            // TODO get available readers and writers

            try {
                var opt_context = new OptionContext ("- produce a PDF from each FILENAME");
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (get_options(), null);
                // TODO add entries from available readers and writers
                opt_context.set_description(
                    ("Processes FILENAME and outputs a PDF.\n" +
                    "Visit %s for more information.\n").printf(
                        PACKAGE_URL));
                opt_context.parse (ref args);
            } catch (OptionError e) {
                printerr ("error: %s\n", e.message);
                return 1;
            }

            if (opt_version) {
                print("%s\nVisit %s for more information\n", PACKAGE_STRING, PACKAGE_URL);
                return 0;
            }

            if(opt_infns == null || opt_infns.length < 1) {
                printerr("Usage: %s FILENAME\n", args[0]);
                return 2;
            }

            if(opt_infns.length > 1 && opt_outfn.length != 0) {
                printerr("-o FILENAME cannot be used with more than one input filename.\n");
                return 2;
            }

            foreach(var infn in opt_infns) {
                try {
                    process_file(infn);
                } catch (FileError e) {
                    printerr ("file error while processing %s: %s\n", infn, e.message);
                    return 1;
                } catch(RegexError e) {
                    printerr ("regex error while processing %s: %s\n", infn, e.message);
                    return 1;
                }
            }

            return 0;
        } // run()

        void process_file(string infn) throws FileError, RegexError
        {
            var infh = File.new_for_path(infn);
            File outfh;

            if(opt_outfn.length != 0) { // Make outfn
                outfh = File.new_for_path(opt_outfn);

            } else {
                var basename = infh.get_basename();
                var re = new Regex("""^(.+)\.(\S+)$""");
                MatchInfo matches;
                if(!re.match(basename, 0, out matches)) {   // just add .pdf
                    outfh = infh.get_parent().get_child(basename + ".pdf");
                } else {
                    var newname = matches.fetch(1) + ".pdf";
                    outfh = infh.get_parent().get_child(newname);
                }
            }

            if(opt_verbose > 0) {
                print("Processing %s to %s\n", infh.get_path(), outfh.get_path());
            }

        } // process_file()
    } // class App
} // My

/** main() */
public static int main(string[] args)
{
    var app = new My.App();
    var status = app.run(strdupv(args));
    if(status != 0) {
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
    }
    return status;
}

