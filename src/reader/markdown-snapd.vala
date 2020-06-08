// reader/markdown-snapd.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Snapd;

/**
 * Markdown reader using snapd-glib.
 *
 * Implementations of this class read input documents.
 */
public class MarkdownSnapdReader {
    /**
     * Read a document.
     * @return A node tree of the document
     */
    public Doc read_document(string filename) throws FileError
    {
        string contents;
        FileUtils.get_contents(filename, out contents);
        var parser = new MarkdownParser(MarkdownVersion.@0);
        parser.set_preserve_whitespace(false);
        return new Doc(parser.parse(contents));
    }
}
