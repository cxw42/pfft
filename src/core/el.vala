// src/core/el.vala - part of pfft, https://github.com/cxw42/pfft
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

/**
 * pfft-specific definitions
 */
namespace My {

    /**
     * Data of a node in the Markdown tree.
     *
     * Each instance holds a unit of text that should be rendered with common
     * attributes.
     *
     * Since the number of Markdown node types is limited, and since Pfft is a
     * lightweight converter, a Elem instance can represent any type of
     * node.  It is essentially an overgrown tagged union.
     *
     * Each Elem instance is either block-level ("div") or
     * character-level ("span").
     *
     * Parent-child relationships are handled by embedding Elem
     * instances in a GLib.Node.
     */
    public class Elem {

        /**
         * The possible element types
         */
        public enum Type {
            /** Invalid element */
            INVALID,

            /**
             * Root node of the document.
             *
             * Does not represent any actual content.
             */
            ROOT,

            // Block-level elements

            /** Header, any level */
            BLOCK_HEADER,
            /** Text paragraph */
            BLOCK_COPY,
            /** Quote */
            BLOCK_QUOTE,
            /** Bulleted list */
            BLOCK_BULLET_LIST,
            /** Numbered list */
            BLOCK_NUMBER_LIST,
            /** List item */
            BLOCK_LIST_ITEM,
            /** Rule */
            BLOCK_HR,
            /** Source code */
            BLOCK_CODE,
            // TODO? tables, html

            // Spans: character-level elements.
            // NOTE: spans CAN be the children of other spans.  E.g.,
            //      **this is _bold italic_ text**

            /**
             * Text that does not carry any formatting of its own.
             *
             * A SPAN_PLAIN may inherit formatting from its parent, so may
             * not be plain text.  Regardless, SPAN_PLAIN does not impose
             * any formatting on its text.
             */
            SPAN_PLAIN,
            /** Italic */
            SPAN_EM,
            /** Bold */
            SPAN_STRONG,
            /** Source code */
            SPAN_CODE,
            /** Strikethrough */
            SPAN_STRIKE,
            /** Underline */
            SPAN_UNDERLINE,

            // TODO? hyperlinks, images, math, wikilinks
        }

        /**
         * What kind of element this is
         */
        public Type ty { get; set; }

        /** Is this element a span? */
        public bool is_span { get {
                                  return (this.ty >= Type.SPAN_PLAIN) && (this.ty <= Type.SPAN_UNDERLINE);
                              } }

        /**
         * The element's text.
         *
         * All elements have text, even if it's empty (e.g., {{{``}}}).
         */
        public string text { get; set; default = ""; }

        // --- Properties for specific types of nodes ---

        /**
         * A header's level (1--6 = h1--h6)
         *
         * Valid only when ty == BLOCK_HEADER.
         */
        public uint header_level { get; set; }

        // --- Constructors ---

        /**
         * Create a new element of the given type.
         */
        public Elem(Type newty)
        {
            ty = newty;
        }

        // --- Accessors and helpers ---
        /**
         * Return a string representation of the node, e.g., for debug prints
         */
        public string as_string()
        {
            return "%s: -%s-".printf(ty.to_string(), text);
        } // as_string

    } // Elem

    /**
     * A document to be rendered
     *
     * Parent-child relationships are handled by GLib.Node.  This is just
     * a convenience class for holding a GLib.Node<Elem> tree.  It provides
     * some debugging methods and saves typing.
     */
    public class Doc {
        /**
         * The root element of the document tree.
         *
         * Assumption: root does not have any siblings.
         */
        public GLib.Node<Elem> root;

        /** Create a doc owning a node tree */
        public Doc(owned GLib.Node<Elem> new_root)
        {
            root = (owned)new_root;
        }

        /**
         * Append the text representation of @node to @sb
         * @return always {{{false}}}, so it can be used in a
         *          GLib.NodeTraverseFunc.
         */
        public static bool dump_node_into(StringBuilder sb, GLib.Node node)
        {
            unowned GLib.Node<Elem> ne = (GLib.Node<Elem>)node;
            unowned Elem el = ne.data;
            sb.append_printf("%sNode: type %s, text -%s-\n",
                string.nfill(2*(node.depth()-1), ' '),
                el.ty.to_string(),
                el.text);
            return false;
        }

        /**
         * Return a string representation of this document
         */
        public string as_string()
        {
            var sb = new StringBuilder();
            sb.append("Document:\n");
            GLib.NodeTraverseFunc cb =
                (node)=>{
                return dump_node_into(sb, node);
            };
            root.traverse(TraverseType.PRE_ORDER, TraverseFlags.ALL, -1, cb);
            return sb.str;
        } // as_string

    } // class Doc

}     // My

// Thanks for advice on the visitors to Li Haoyi's article
// https://www.lihaoyi.com/post/ZeroOverheadTreeProcessingwiththeVisitorPattern.html
