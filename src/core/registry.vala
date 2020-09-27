// core/registry.vala
//
// Vala definitions for src/core/pfft-register.h.
//
// This is a .vala file, not a .vapi file, so its definitions will be
// re-exported as part of pfft-core.vapi.
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My.Log;

namespace My {

    /**
     * Map from friendly names to GTypes.
     *
     * Used to store and sort readers and writers.
     */
    public class ClassMap : Gee.TreeMap<string, GLib.Type> {

        /** Set object properties from 'name=value' pairs */
        private static void set_options_on(Object target, string[] options,
            string class_name)
        throws KeyFileError
        {
            // property accessor for the instance we are creating
            ObjectClass ocl = (ObjectClass) target.get_type().class_ref ();

            // Assign the properties
            var num_opts = (options == null) ? 0 : strv_length(options);
            for(int i=0; i<num_opts; ++i) {
                var optspec = options[i];
                var nv = optspec.split("=", 2);
                if(nv.length != 2) {
                    throw new KeyFileError.INVALID_VALUE(
                              "%s: Invalid option %s".printf(class_name, optspec));
                }

                var prop = ocl.find_property(nv[0]);
                if(prop == null || prop.get_name()[0] == 'P') { // skip unknown, private
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

                // TODO unit conversion for properties with dimen values, a la
                // Template.

                target.set_property(nv[0], val);
                linfoo(target, "Set property %s from command line to %s",
                    nv[0], val.type() == typeof(string) ? @"'$(val.get_string())'" :
                    Gst.Value.serialize(val)    // LCOV_EXCL_LINE - can't guarantee this will fire during tests
                );

            } // foreach option
        } // set_options_on()

        /**
         * Create an instance and set its properties.
         *
         * Sets properties from @template first, then from @options.
         * @param m             The class registry to use
         * @param class_name    The name of the class to instantiate.
         *                      This may be different from the name in the
         *                      source code.
         * @param template      Optional My.Template.  Properties that exist
         *                      both in the template and the target class
         *                      will be copied from the target to the
         *                      new instance.
         * @param options       Optional 'property=value' assigments.
         * @return The new instance, or null.
         */
        public Object create_instance(string class_name,
            Template? template, string[]? options) throws KeyFileError
        {
            if(!this.has_key(class_name)) {
                throw new KeyFileError.KEY_NOT_FOUND(
                          "%s: Class not registered".printf(class_name));
            }

            var type = this.get(class_name);
            Object retval = Object.new(type);

            if(retval == null) {
                return null;    // LCOV_EXCL_LINE - I don't know any way to force this to happen during testing
            }

            if(template!=null) {
                template.set_props_on(retval);
            }

            if(options != null) {
                set_options_on(retval, options, class_name);
            }

            return retval;
        } // create_instance()
    } // class ClassMap

    /**
     * Get a reference to the registry of classes.
     *
     * On startup, any reader or writer class can register its GType with
     * this registry.  The registry maps from string names to GTypes.
     * The registry does not free any keys or values.
     *
     * A GLib hashtable stores gpointer values.  A GType is a gsize, a
     * gpointer, or a gulong.  gsize is documented as being large enough
     * to hold the numerical value of a pointer, and gulong is documented as
     * being the same type as a gsize.
     *
     * The name used as the hash key does not have to be the same as the
     * type name.  You can use friendly names or other strings.
     */
    [CCode(cheader_filename = "registry.h")]
    public extern unowned GLib.HashTable<string, GLib.Type> get_registry();

    /**
     * Convenience function for registering a type.
     * @param name      The handle of the type.  This can be different from any
     *                  names the type may have in Vala or GLib.
     * @param type      The type's GType
     * @param filename  Only used for debugging
     * @param lineno    Only used for debugging
     */
    [CCode(cheader_filename = "registry.h")]
    public extern void register_type(string name, GLib.Type type,
        string filename, uint lineno);

    /**
     * A property of this name holds a nick and blurb for the class itself.
     */
    public const string CLASS_META_PROPERTY_NAME = "meta";

    /**
     * A class whose meta property has this nick is the default class to use.
     *
     * Out of all classes that implement a particular interface, that is.
     */
    public const string CLASS_META_NICK_DEFAULT = "default";

} // My
