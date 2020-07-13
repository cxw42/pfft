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
            // Constraint: spans cannot be the children of other spans.

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

    /** Visitor interface for Elems */
    [GenericAccessors]
    public interface ElemVisitor<T>: Object {

        // --- Visitor functions --------------------------------------------
        // These functions process various types of Elem nodes.  The default
        // implementation warns and is a no-op.
        //
        // Each Elem.Type is given its own function so that the typeswitch
        // can happen one place, and since I am not currently using separate
        // subclasses for different Elem.Types.

        // Start functions

#if 0
        protected ElemVisitor<T>? unhandled_start(Elem el)
        {
            warning("Visitor of type %s doesn't know how to start handling elements of type %s",
                this.get_type().name(), el.ty.to_string());
            return null;
        }

        public virtual ElemVisitor<T>? start_invalid(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_root(Elem el) {
            return unhandled_start(el);
        }

        public virtual ElemVisitor<T>? start_block_header(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_block_copy(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_block_quote(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_block_bullet_list(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_block_number_list(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_block_list_item(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_block_hr(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_block_code(Elem el) {
            return unhandled_start(el);
        }

        public virtual ElemVisitor<T>? start_span_plain(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_span_em(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_span_strong(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_span_code(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_span_strike(Elem el) {
            return unhandled_start(el);
        }
        public virtual ElemVisitor<T>? start_span_underline(Elem el) {
            return unhandled_start(el);
        }
#endif

        // Accept functions

        protected void unhandled_elem(Elem el)
        {
            warning("Visitor of type %s doesn't know how to handle elements of type %s",
                this.get_type().name(), el.ty.to_string());
        }

        public virtual void accept_invalid(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_root(Elem el) {
            unhandled_elem(el);
        }

        public virtual void accept_block_header(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_block_copy(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_block_quote(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_block_bullet_list(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_block_number_list(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_block_list_item(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_block_hr(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_block_code(Elem el) {
            unhandled_elem(el);
        }

        public virtual void accept_span_plain(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_span_em(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_span_strong(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_span_code(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_span_strike(Elem el) {
            unhandled_elem(el);
        }
        public virtual void accept_span_underline(Elem el) {
            unhandled_elem(el);
        }

        /** Called to produce a visitor to be used for child nodes */
        public virtual ElemVisitor<T> getChildVisitor()
        {
            return this;
        }

        /** Called when the node and all its children are done */
        public virtual T? done()
        {
            return null;
        }
    } // interface ElemVisitor

    /** Run an ElemVisitor over an Elem tree */
    public T? dispatch_elem<T>(GLib.Node<Elem>? node, ElemVisitor<T> visitor)
    {
        if(node == null) {
            return null;
        }
        unowned Elem el = node.data;

        switch(el.ty) {
        case INVALID: visitor.accept_invalid(el); break;
        case ROOT: visitor.accept_root(el); break;

        case BLOCK_HEADER: visitor.accept_block_header(el); break;
        case BLOCK_COPY: visitor.accept_block_copy(el); break;
        case BLOCK_QUOTE: visitor.accept_block_quote(el); break;
        case BLOCK_BULLET_LIST: visitor.accept_block_bullet_list(el); break;
        case BLOCK_NUMBER_LIST: visitor.accept_block_number_list(el); break;
        case BLOCK_LIST_ITEM: visitor.accept_block_list_item(el); break;
        case BLOCK_HR: visitor.accept_block_hr(el); break;
        case BLOCK_CODE: visitor.accept_block_code(el); break;

        case SPAN_PLAIN: visitor.accept_span_plain(el); break;
        case SPAN_EM: visitor.accept_span_em(el); break;
        case SPAN_STRONG: visitor.accept_span_strong(el); break;
        case SPAN_CODE: visitor.accept_span_code(el); break;
        case SPAN_STRIKE: visitor.accept_span_strike(el); break;
        case SPAN_UNDERLINE: visitor.accept_span_underline(el); break;

        default:
            warning(@"Unhandled element type $(el.ty.to_string())");
            return null;
        }

        ElemVisitor<T> child_visitor = visitor.getChildVisitor();

        node.children_foreach(TraverseFlags.ALL, (child) => {
            dispatch_elem(child, child_visitor);
        });

        return visitor.done();
    } // dispatch_elem()

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
