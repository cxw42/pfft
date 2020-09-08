// writer/dumper.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {

    public class TreeDumperWriter : Object, Writer {
        /** Metadata for this class */
        [Description(blurb = "Dump pfft's internal representation of the document (for debugging)")]
        public bool meta { get; default = false; }

        public void write_document(string filename, Doc doc,
            string? source_fn = null)
        throws FileError, My.Error
        {
            emit(filename, doc.as_string());
        }
    }
}
