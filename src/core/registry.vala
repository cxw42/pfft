// core/registry.vala
//
// Vala definitions for src/core/pfft-register.h.
//
// This is a .vala file, not a .vapi file, so its definitions will be
// re-exported as part of pfft-core.vapi.
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {
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
     */
    [CCode(cheader_filename = "registry.h")]
    public extern void register_type(string name, GLib.Type type,
        string filename, uint lineno);

    /**
     * A property of this name holds a nick and blurb for the class itself.
     */
    public const string CLASS_META_PROPERTY_NAME = "meta";
} // My
