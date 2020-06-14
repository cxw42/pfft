// reader/markdown-snapd.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Snapd;

namespace My
{

    /**
     * Markdown reader using snapd-glib.
     */
    public class MarkdownSnapdReader: Object, Reader {

        /**
         * Create and attach a My.GLib.Node<Elem> representing a Snapd.MarkdownNode.
         * @param parent    The node to attach to
         * @param mkid      The child on which to base the new node.
         * @return The new child node, if any
         */
        private static unowned GLib.Node<Elem>? make_and_attach(
            /*unowned*/ GLib.Node<Elem> parent, MarkdownNode mkid)
        {
            Test.message("%s", as_diag("> parent %p, mkid %p".printf(parent, mkid)));
            unowned GLib.Node<Elem>? retval;
            string mtext = (mkid.get_text() != null) ? mkid.get_text() : "";
            var mty = mkid.get_node_type();

            Test.message("%s", as_diag(
                    "Node ty %s text -%s-".printf(mty.to_string(),
                    mtext)));
            if(mty == MarkdownNodeType.TEXT) {
                retval = null;
                // TODO add whitespace?

                // XXX HACK - promote parents to headers
                if(mtext[0 : 2]=="# " && parent.data.text == "" && parent.data.ty == Elem.Type.BLOCK_COPY) {
                    parent.data.ty = Elem.Type.BLOCK_HEADER;
                    mtext = mtext[2 : mtext.length];
                }
                parent.data.text += mtext;
                Test.message("%s", as_diag("Appended -%s-; now -%s-".printf(mtext, parent.data.text)));

            } else if(  // Handle block elements
                mty == MarkdownNodeType.CODE_BLOCK ||
                mty == MarkdownNodeType.LIST_ITEM ||
                mty == MarkdownNodeType.PARAGRAPH ||
                mty == MarkdownNodeType.UNORDERED_LIST ||
                parent == null // Promote top-level inline to block
            ) {
                var newnode = node_of_ty(Elem.Type.BLOCK_COPY);
                newnode.data.text = mtext;
                retval = newnode;
                parent.append((owned)newnode);  // now newnode is null

            } else { // Handle inline elements
                retval = null;
                parent.data.text += mtext;
            }

            Test.message("%s", as_diag("< parent %p, mkid %p, retval %p".printf(parent, mkid, retval)));
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
                Test.message("%s", as_diag("] parent %p, mkid %p, no. %d".printf(parent, mkid, i)));
                unowned GLib.Node<Elem> kid = make_and_attach(parent, mkid);
                // If mkid didn't need a new node, attach children of
                // mkid to the parent of mkid.
                build_tree(kid ?? parent,
                    (GenericArray<unowned MarkdownNode>)mkid.get_children());
                Test.message("%s", as_diag("[ parent %p, mkid %p, no. %d, kid %p".printf(parent, mkid, i, kid)));
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

        /**
         * Read a file and build a node tree for it.
         */
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
