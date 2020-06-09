// reader/markdown-snapd.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Snapd;

namespace My
{

    /**
     * Markdown reader using snapd-glib.
     */
    public class MarkdownSnapdReader {

        /**
         * Create and attach a My.GLib.Node<Elem> representing a Snapd.MarkdownNode.
         * @param parent    The node to attach to
         * @param mkid      The child on which to base the new node.
         * @return The new child node, if any
         */
        private static GLib.Node<Elem>? make_and_attach(GLib.Node<Elem> parent, MarkdownNode mkid)
        {
            GLib.Node<Elem>? retval;
            string mtext = (mkid.get_text() != null) ? mkid.get_text() : "";
            var mty = mkid.get_node_type();

            if(mty == MarkdownNodeType.TEXT) {
                retval = null;
                parent.data.text += mtext;  // TODO add whitespace?

            } else if(  // Handle block elements
                mty == MarkdownNodeType.CODE_BLOCK ||
                mty == MarkdownNodeType.LIST_ITEM ||
                mty == MarkdownNodeType.PARAGRAPH ||
                mty == MarkdownNodeType.UNORDERED_LIST ||
                parent == null // Promote top-level inline to block
            ) {
                retval = node_of_ty(Elem.Type.BLOCK_COPY);
                retval.data.text = mtext;
                parent.append((owned)retval);

            } else { // Handle inline elements
                retval = null;
                parent.data.text += mtext;
            }

            return retval;
        } // make_and_attach()

        /**
         * Traverse a MarkdownNode and build a GLib.Node<Elem>.
         * @param parent    The parent node, which must exist
         * @param newkids   Array of child node(s) to add to the parent
         */
        private static void build_tree(GLib.Node<Elem> parent,
            GenericArray<unowned MarkdownNode>? newkids)
        {
            if(newkids == null || newkids.length == 0) {
                return;
            }

            for(int i=0; i<newkids.length; ++i) {
                MarkdownNode mkid = newkids.get(i);
                var kid = make_and_attach(parent, mkid);
                // If mkid didn't need a new node, attach children of
                // mkid to the parent of mkid.
                build_tree(kid ?? parent,
                    (GenericArray<unowned MarkdownNode>)mkid.get_children());
            }
        } // build_tree()

        /**
         * Read a document.
         * @return A node tree of the document
         */
        public Doc read_document(string filename) throws FileError
        {
            GLib.Node<Elem> root = tree_for(filename);
            return new Doc((owned)root);
        }

        private GLib.Node<Elem> tree_for(string filename) throws FileError
        {
            // Read it in
            string contents;
            FileUtils.get_contents(filename, out contents);
            var parser = new MarkdownParser(MarkdownVersion.@0);
            parser.set_preserve_whitespace(false);
            var parsed = parser.parse(contents);

            // Build a GLib.Node<Elem> tree
            var root = node_of_ty(Elem.Type.ROOT);
            build_tree(root, parsed);
            return root;
        }
    }
} // My
