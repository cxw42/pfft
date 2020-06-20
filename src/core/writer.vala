// writer.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

namespace My {
    /**
     * Document writer.
     *
     * Implementations of this class produce output files from
     * documents read by a My.Reader implementation.
     */
    public interface Writer : Object {
        /**
         * Write a document to a file.
         * @param filename  The name of the file to write
         * @param doc       The document to write
         */
        public abstract void write_document(string filename, Doc doc) throws FileError;
    }
} // My
