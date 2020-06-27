// pfft.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {
    // Types {{{1
    /**
     * Our own definition for gst_value_deserialize().
     *
     * Per <https://gitlab.gnome.org/GNOME/vala/-/issues/1014>, older
     * valac versions have an incorrect binding for gst_value_deserialize().
     */
    [CCode (cheader_filename = "gst/gst.h", cname = "gst_value_deserialize")]
    extern bool deserialize_value (ref GLib.Value dest, string src);

    /**
     * Map from friendly names to GTypes.
     *
     * Used to store and sort readers and writers.
     * This is a typedef.
     */
    private class ClassMap : Gee.TreeMap<string, GLib.Type> { }

    // }}}1

    /**
     * Main application class for pfft
     */
    public class App {

        // Command-line parsing {{{1

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
        [CCode(array_length = false)]
        private string[]? opt_infns;

        /** Which reader to use */
        private string opt_reader_name;

        /** reader options */
        [CCode(array_length = false)]
        private string[]? opt_reader_options;

        /**
         * Where to output.
         *
         * In the system filename encoding.  If not given, run() will
         * auto-generate the output name.
         */
        private string opt_outfn = "";

        /** Which writer to use */
        private string opt_writer_name;

        /** writer options */
        [CCode(array_length = false)]
        private string[]? opt_writer_options;

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
                       // --reader, -R READER
                       { "reader", 'R', 0, OptionArg.STRING, &opt_reader_name, "Which reader to use", "READER" },

                       // --ro NAME=VALUE: reader options
                       { "ro", 0, 0, OptionArg.STRING_ARRAY, &opt_reader_options, "Set a reader option", "NAME=VALUE" },

                       // --output, -o FIlENAME
                       { "output", 'o', 0, OptionArg.FILENAME, &opt_outfn, "Output filename (provided only one input filename is given)", "FILENAME" },

                       // --writer, -W WRITER
                       { "writer", 'W', 0, OptionArg.STRING, &opt_writer_name, "Which writer to use", "WRITER" },

                       // --wo NAME=VALUE: writer options
                       { "wo", 0, 0, OptionArg.STRING_ARRAY, &opt_writer_options, "Set a writer option", "NAME=VALUE" },

                       // FILENAME* (non-option arg(s) - inputs)
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

        // }}}1
        // Instance data {{{1
        ClassMap readers_;
        string reader_default_;
        ClassMap writers_;
        string writer_default_;

        // }}}1
        // Main routines {{{1

        /**
         * Main routine.
         * @param   args    A strv of the input arguments.  NOT the exact args[]
         *                  passed to main().
         */
        public int run(owned string[] args)
        {
            Intl.setlocale (LocaleCategory.ALL, "");    // init locale from environment
            string[] dummy_args = {""};
            unowned var dargs = dummy_args;
            Gst.init(ref dargs);

            // TODO get available readers and writers
            readers_ = new ClassMap();
            writers_ = new ClassMap();
            load_from_registry();
            assert_true(!readers_.is_empty);
            assert_true(!writers_.is_empty);

            try {
                var opt_context = new OptionContext ("- produce a PDF from each FILENAME");
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (get_options(), null);
                // TODO add entries from available readers and writers
                opt_context.set_description(
                    ("Processes FILENAME and outputs a PDF.\n" +
                    "Visit %s for more information.\n" +
                    "\n%s").printf(PACKAGE_URL, get_rw_help()));
                opt_context.parse_strv (ref args);
            } catch (OptionError e) {
                printerr ("error: %s\n", e.message);
                return 1;
            }

            if (opt_version) {
                print("%s\nVisit %s for more information\n", PACKAGE_STRING, PACKAGE_URL);
                return 0;
            }

            var num_infns = (opt_infns == null) ? 0 : strv_length(opt_infns);
            if(num_infns < 1) {
                printerr("Usage: %s FILENAME\n", args[0]);
                return 2;
            }

            if(num_infns > 1 && opt_outfn.length != 0) {
                printerr("-o FILENAME cannot be used with more than one input filename.\n");
                return 2;
            }

            /* Create the plugins */
            Reader reader;
            Writer writer;
            try {
                reader = create_instance(
                    readers_, opt_reader_name ?? reader_default_, opt_reader_options) as Reader;
            } catch(KeyFileError e) {
                printerr ("Could not create reader: %s\n", e.message);
                return 1;
            }

            try {
                writer = create_instance(
                    writers_, opt_writer_name ?? writer_default_, opt_writer_options) as Writer;
            } catch(KeyFileError e) {
                printerr ("Could not create writer: %s\n", e.message);
                return 1;
            }

            if(reader == null) {
                printerr("Could not create reader %s\n",
                    opt_reader_name ?? reader_default_);
                return 1;
            }

            if(writer == null) {
                printerr("Could not create writer %s\n",
                    opt_writer_name ?? writer_default_);
                return 1;
            }

            /* Do the work */
            for(uint i=0; i<num_infns; ++i) {
                var infn = opt_infns[i];
                try {
                    process_file(infn, reader, writer);
                } catch (FileError e) {
                    printerr ("file error while processing %s: %s\n", infn, e.message);
                    return 1;
                } catch(MarkupError e) {
                    printerr ("markup error while processing %s: %s\n", infn, e.message);
                    return 1;
                } catch(RegexError e) {
                    printerr ("regex error while processing %s: %s\n", infn, e.message);
                    return 1;
                } catch(My.Error e) {
                    printerr ("error while processing %s: %s\n", infn, e.message);
                    return 1;
                }
            }

            return 0;
        } // run()

        void process_file(string infn, Reader reader, Writer writer)
        throws FileError, MarkupError, RegexError, My.Error
        {
            print("Processing %s\n", infn);

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

            var doc = reader.read_document(infh.get_path());
            writer.write_document(outfh.get_path(), doc);

        } // process_file()

        // }}}1
        // Registry functions {{{1

        /** Retrieve readers and writers from the registry */
        void load_from_registry()
        {
            var registry = get_registry();
            // print("Registry has %u keys\n", registry.size());

            registry.foreach( (name, type) => {
                if(type.is_a(typeof(Reader))) {
                    readers_.set(name, type);
                }

                if(type.is_a(typeof(Writer))) {
                    writers_.set(name, type);
                }

            });
        } // load_from_registry()

        /** Retrieve information about the available readers and writers */
        string get_rw_help()
        {
            var sb = new StringBuilder();
            if(!readers_.is_empty) {
                sb.append("Available readers (* = default):\n");
                sb.append(get_classmap_help(readers_, out reader_default_));
            }
            if(!writers_.is_empty) {
                if(!readers_.is_empty) {
                    sb.append_c('\n');
                }
                sb.append("Available writers (* = default):\n");
                sb.append(get_classmap_help(writers_, out writer_default_));
            }
            return sb.str;
        } // get_rw_help()

        /** Pretty-print information from a ClassMap */
        string get_classmap_help(ClassMap m, out string default_class)
        {
            var sb = new StringBuilder();
            default_class = "";

            // Pass 1: get the default, if there is one.
            foreach(string name in m.ascending_keys) {
                var type = m.get(name);
                ObjectClass ocl = (ObjectClass) type.class_ref ();
                var class_meta = ocl.find_property(CLASS_META_PROPERTY_NAME);
                if(class_meta != null &&
                    (class_meta.get_nick() == CLASS_META_NICK_DEFAULT))
                {
                    default_class = name;
                    break;
                }
            }

            foreach(string name in m.ascending_keys) {
                if(default_class == "") {   // in case we didn't find one before
                    default_class = name;
                }

                var type = m.get(name);
                ObjectClass ocl = (ObjectClass) type.class_ref ();

                var class_meta = ocl.find_property(CLASS_META_PROPERTY_NAME);
                sb.append_printf("  %c %s%s%s\n",
                    (name == default_class) ? '*' : ' ',
                    name,
                    (class_meta != null) ? " - " : "",
                    (class_meta != null) ? class_meta.get_blurb() : "");

                var props = ocl.list_properties();
                if( props.length>1 || (props.length>0 && class_meta == null) ) {
                    sb.append("      Properties:\n");
                    foreach (ParamSpec spec in ocl.list_properties ()) {
                        if(spec.get_name() != CLASS_META_PROPERTY_NAME) {
                            sb.append_printf("          %s - %s\n",
                                spec.get_name(),
                                spec.get_blurb());
                        }
                    }
                }
            }

            return sb.str;
        } // get_classmap_help

        /** Create an instance and set its properties */
        Object create_instance(ClassMap m, string class_name,
            string[]? options) throws KeyFileError
        {
            if(!m.has_key(class_name)) {
                throw new KeyFileError.KEY_NOT_FOUND(
                          "%s: Class not registered".printf(class_name));
            }

            var type = m.get(class_name);
            Object retval = Object.new(type);

            if(options == null) {
                return retval;  // *** EXIT POINT ***
            }

            // Assign the properties
            ObjectClass ocl = (ObjectClass) type.class_ref ();
            var num_opts = (options == null) ? 0 : strv_length(options);
            for(int i=0; i<num_opts; ++i) {
                var optspec = options[i];
                var nv = optspec.split("=", 2);
                if(nv.length != 2) {
                    throw new KeyFileError.INVALID_VALUE(
                              "%s: Invalid option %s".printf(class_name, optspec));
                }

                // print("Trying %p->%s := %s\n", retval, nv[0], nv[1]);
                var prop = ocl.find_property(nv[0]);
                if(prop == null) {
                    throw new KeyFileError.KEY_NOT_FOUND(
                              "%s: %s is not an option I understand".printf(
                                  class_name, nv[0]));
                }

                var val = GLib.Value(prop.value_type);
                if(!deserialize_value(ref val, nv[1])) {
                    throw new KeyFileError.INVALID_VALUE(
                              "%s: Invalid value %s for option %s".printf(
                                  class_name, nv[1], nv[0]));
                }

                // print("  value = %s\n", Gst.Value.serialize(val));
                retval.set_property(nv[0], val);
            } // foreach option

            return retval;
        }


        // }}}1
    } // class App
} // My

/** main() */ // {{{1
public static int main(string[] args)
{
    var app = new My.App();
    var arg_copy = strdupv(args);
    var status = app.run((owned)arg_copy);
    if(status != 0) {
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
    }
    return status;
}

// }}}1
// vi: set fdm=marker: //
