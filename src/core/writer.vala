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
        public abstract void write_document(string filename, Doc doc)
        throws FileError, My.Error;

        /**
         * Convenience function to map filename "-" to stdout
         */
        public void emit(string filename, string contents)
            throws FileError
        {
            if(filename == "-") {
                print(contents);
            } else {
                FileUtils.set_contents(filename, contents);
            }
        } //emit()
    }
} // My
