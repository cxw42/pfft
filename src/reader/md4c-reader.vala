// src/reader/md4c-reader.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Md4c;

namespace My
{
    /**
     * g_strndup() available to the public!
     *
     * The VAPI for GLib doesn't currently expose this function directly.
     */
    [CCode (cheader_filename = "reader-shim.h", cname = "g_strndup_shim")]
    public extern string strndup (char* str, size_t n);

    /**
     * Markdown reader using md4c
     */
    public class MarkdownMd4cReader : Object, Reader {
        /** Metadata for this class */
        [Description(blurb = "Read CommonMark Markdown files")]
        public bool meta { get; default = false; }

#if 0
        /**
         * Create and attach a My.GLib.Node<Elem> representing a Snapd.MarkdownNode.
         * @param depth     Current depth, for debugging
         * @param parent    The node to attach to
         * @param mkid      The child on which to base the new node.
         * @return The new child node, if any
         */
        private static unowned GLib.Node<Elem>? make_and_attach(
            int depth,
            /*unowned*/ GLib.Node<Elem> parent, MarkdownNode mkid)
        {
#if EXTRA_VERBOSE
            Test.message("%s", as_diag("> parent %p, mkid %p".printf(parent, mkid)));
#endif
            unowned GLib.Node<Elem>? retval;
            string mtext = (mkid.get_text() != null) ? mkid.get_text() : "";
            var mty = mkid.get_node_type();

            Test.message("%s", as_diag(
                    "%sNode ty %s text -%s-".printf(
                        string.nfill(depth*2, ' '),
                        mty.to_string(),
                        mtext)));
            if(mty == MarkdownNodeType.TEXT) {
                retval = null;
                // TODO add whitespace?

                // XXX HACK - promote parents to headers
                if(mtext[0 : 2]=="# " && parent.data.text == "" && parent.data.ty == Elem.Type.BLOCK_COPY) {
                    parent.data.ty = Elem.Type.BLOCK_HEADER;
                    parent.data.header_level = 1;   // XXX
                    mtext = mtext[2 : mtext.length];
                }
                parent.data.text += mtext;
#if EXTRA_VERBOSE
                Test.message("%s", as_diag("Appended -%s-; now -%s-".printf(mtext, parent.data.text)));
#endif

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

#if EXTRA_VERBOSE
            Test.message("%s", as_diag("< parent %p, mkid %p, retval %p".printf(parent, mkid, retval)));
#endif
            return retval;
        } // make_and_attach()

        /**
         * Traverse a MarkdownNode and build a GLib.Node<Elem>.
         * @param depth     Current depth, for debugging
         * @param parent    The parent node, which must exist
         * @param newkids   Array of child node(s) to add to the parent
         */
        private static void build_tree(int depth, GLib.Node<Elem> parent,
            GenericArray<unowned MarkdownNode>? newkids)
        {
            if(newkids == null || newkids.length == 0) {
                return;
            }

            for(int i=0; i<newkids.length; ++i) {
                MarkdownNode mkid = newkids.get(i);
#if EXTRA_VERBOSE
                Test.message("%s", as_diag("] parent %p, mkid %p, no. %d".printf(parent, mkid, i)));
#endif
                unowned GLib.Node<Elem> kid = make_and_attach(depth+1, parent, mkid);
                // If mkid didn't need a new node, attach children of
                // mkid to the parent of mkid.
                build_tree(depth+1, kid ?? parent,
                    (GenericArray<unowned MarkdownNode>)mkid.get_children());
#if EXTRA_VERBOSE
                Test.message("%s", as_diag("[ parent %p, mkid %p, no. %d, kid %p".printf(parent, mkid, i, kid)));
#endif
            }
        } // build_tree()
#endif

        /**
         * Read a document.
         * @return A node tree of the document
         */
        public Doc read_document(string filename) throws FileError, MarkupError
        {
            GLib.Node<Elem> root = tree_for(filename);
            return new Doc((owned)root);
        }

        /**
         * Indentation based on depth_.
         *
         * A string with four spaces per depth_.  Updated by the setter
         * for depth_.
         */
        private string indent_ = "";

        /** Storage of the current indentation level */
        private int depth_value_ = 0;

        /** Helper for tree_for() since I don't have a closure at present */
        private int depth_ {
            get { return depth_value_; }
            set {
                depth_value_ = value;
                indent_ = string.nfill(depth_*4, ' ');
            }
        }

        /** md4c callback */
        private static int enter_block_(BlockType block_type, void *detail, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            print("%sGot block %s\n",
                self.indent_, block_type.to_string());
            ++self.depth_;
            return 0;
        }

        /** md4c callback */
        private static int leave_block_(BlockType block_type, void *detail, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            --self.depth_;
            print("%sLeaving block %s\n",
                self.indent_, block_type.to_string());
            return 0;
        }

        /** md4c callback */
        private static int enter_span_(SpanType span_type, void *detail, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            print("%sGot span %s ... ",
                self.indent_, span_type.to_string());
            return 0;
        }

        /** md4c callback */
        private static int leave_span_(SpanType span_type, void *detail, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            print("left span %s\n", span_type.to_string());
            return 0;
        }

        private static int text_(TextType text_type, /*const*/ Char? text, Size size, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            var data = strndup((char *)text, size);
            print("%s<<%s>>\n", self.indent_, data);
            return 0;
        }

        /**
         * Read a file and build a node tree for it.
         */
        private GLib.Node<Elem> tree_for(string filename) throws FileError, MarkupError
        {
            // Read it in
            string contents;
            FileUtils.get_contents(filename, out contents);
            // TODO var parser = new MarkdownParser(MarkdownVersion.@0);
            // parser.set_preserve_whitespace(false);
            // var parsed = parser.parse(contents);
            Md4c.Parser parser = new Parser();

            // Processing functions
            // NOTE: no closure

            parser.enter_block = enter_block_;
            parser.leave_block = leave_block_;
            parser.enter_span = enter_span_;
            parser.leave_span = leave_span_;
            parser.text = text_;
            parser.debug_log = null;

            depth_ = 0;
            var ok = Md4c.parse((Char?)contents, contents.length, parser, this);
            if(ok != 0) {
                throw new MarkupError.PARSE("parse failed (%d)".printf(ok));
            }

            // Build a GLib.Node<Elem> tree
            var root = node_of_ty(Elem.Type.ROOT);
            // TODO build_tree(0, root, parsed);
            return root;
        }
    }
} // My
