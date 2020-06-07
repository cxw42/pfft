// doc.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

/**
 * A document to be rendered.
 *
 * This class holds the contents of a parsed document.
 */
public class Doc {
    /**
     * The document
     */
    public GenericArray<unowned Snapd.MarkdownNode> content;

    /**
     * Basic constructor
     * @param document The new document to store
     */
    public Doc(GenericArray<unowned Snapd.MarkdownNode> document)
    {
        content = document;
    }
}

