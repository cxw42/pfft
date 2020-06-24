// doc.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {

    /**
     * Custom errors produced by pfft
     */
    public errordomain Error {
        /** Function not implemented */
        UNIMPL,

        /** Error while reading */
        READER,

        /** Error while writing */
        WRITER,
    }

    /**
     * Format a string as TAP diagnostic output.
     */
    public string as_diag(string ins)
    {
        string prefix = (ins[0] == '#') ? "" : "# ";
        return prefix + ins.replace("\n", "\n# ");
    }

    /**
     * Create a My.Elem and its containing GLib.Node at the same time
     */
    public GLib.Node<Elem> node_of_ty(Elem.Type newty)
    {
        return new GLib.Node<Elem>(new Elem(newty));
    }

} // My
