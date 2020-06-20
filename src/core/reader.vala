// reader.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {
    /**
     * Document reader.
     *
     * Implementations of this class read input documents.
     */
    public interface Reader : Object {
        /**
         * Read a document.
         * @return A node tree of the document
         */
        public abstract Doc read_document(string filename) throws FileError;
    }
} // My
