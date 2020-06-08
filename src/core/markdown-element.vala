// src/core/uniform-node.vala - part of pfft, https://github.com/cxw42/pfft
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

/**
 * Data of a node in the Markdown tree.
 *
 * Each instance holds a unit of text that should be rendered with common
 * attributes.
 *
 * Since the number of Markdown node types is limited, and since Pfft is a
 * lightweight converter, a MarkdownElement instance can represent any type of
 * node.  It is essentially an overgrown tagged union.
 *
 * Each MarkdownElement instance is either block-level ("div") or
 * character-level ("span").
 *
 * Parent-child relationships are handled by embedding MarkdownElement
 * instances in a GLib.Node.
 */
public class MarkdownElement {

    /**
     * The possible element types
     */
    public enum Type {
        /** Header, any level */
        BLOCK_HEADER,
        /** Text paragraph */
        BLOCK_COPY,
        /** Code block */
        BLOCK_CODE,
    }

    /**
     * What kind of element this is
     */
    public Type ty { get; set; }

    /**
     * The element's text.
     *
     * All elements have text, even if it's empty (e.g., {{{``}}}).
     */
    public string text { get; set; }

    /**
     * Return a string representation of the node, e.g., for debug prints
     */
    public string as_string()
    {
        return "%s: -%s-".printf(ty.to_string(), text);
    } // to_string

    /**
     * Render the element to Pango markdown ("pmark")
     */
    public string as_pmark()
    {
        return "TODO";
    }
}

