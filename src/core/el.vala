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
        public string text { get; set; default = ""; }

        // --- Properties for specific types of nodes ---

        /**
         * A header's level (1--6 = h1--h6)
         *
         * Valid only when ty == BLOCK_HEADER.
         */
        public int header_level { get; set; }

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
        } // to_string

        /**
         * Render the element to Pango markdown ("pmark")
         */
        public string as_pmark()
        {
            return "TODO";
        }
    } // Elem

    /**
     * A document to be rendered
     *
     * Parent-child relationships are handled by GLib.Node.
     */
    public class Doc {
        /** The root element of the document tree */
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

    }

}     // My
