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

    /**
     * Wrap a string in TAP markers.
     *
     * NOTE: discards trailing whitespace.
     */
    private string tap_wrap(string s)
    {
        var s1 = s;
        s1._chomp();
        var retval = "# " + s1.replace("\n", "\n# ") + "\n";
        return retval;
    }

    /** Format a string as a TAP diagnostic message. */
    [PrintfFormat]
    public string diag_string (string format, ...)
    {
        var l = va_list();
        var raw = format.vprintf(l);
        var retval = tap_wrap(raw);
        return retval;
    } // diag_string()

    /**
     * Print a TAP diagnostic message to stdout.
     *
     * For use in test files in t/.
     */
    [PrintfFormat]
    public void diag (string format, ...)
    {
        var l = va_list();
        var raw = format.vprintf(l);
        var retval = tap_wrap(raw);
        print("%s", retval);
    } // diag()

} // My
