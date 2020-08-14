// src/reader/md4c-reader.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Md4c;
using My.Log;

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

        /**
         * Read a document.
         * @return A node tree of the document
         */
        public Doc read_document(string filename) throws FileError, MarkupError
        {
            make_tree_for(filename);
            return new Doc((owned)root_);
        }

        // === Parser callbacks and data ===================================

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

        /** The root of the tree we are building */
        private GLib.Node<Elem> root_;

        /** The current node */
        private unowned GLib.Node<Elem> node_;

        /**
         * md4c callback for entering blocks.
         *
         * Sets node_ to a SPAN_PLAIN if the block was of a recognized type.
         */
        private static int enter_block_(BlockType block_type, void *detail, void *userdata)
        {
            GLib.Node<Elem> newnode = null;

            var self = (MarkdownMd4cReader)userdata;
            print("%sGot block %s\n",
                self.indent_, block_type.to_string());
            ++self.depth_;

            switch(block_type) {
            case DOC:
                self.node_ = self.root_;
                break;

            case QUOTE:
                newnode = node_of_ty(BLOCK_QUOTE);
                break;

            case UL:
                newnode = node_of_ty(BLOCK_BULLET_LIST);
                break;

            case OL:
                newnode = node_of_ty(BLOCK_NUMBER_LIST);
                break;

            case LI:
                newnode = node_of_ty(BLOCK_LIST_ITEM);
                break;

            case HR:
                newnode = node_of_ty(BLOCK_HR);
                break;

            case H:
                var det = (BlockHDetail*)detail;
                newnode = node_of_ty(BLOCK_HEADER);
                newnode.data.header_level = det.level;
                break;

            case CODE:
                newnode = node_of_ty(BLOCK_CODE);
                newnode.data.info_string = get_info_string(detail);
                newnode.data.info_string._chomp();
                ldebugo(self, "Info string -%s-",  newnode.data.info_string);
                break;

            case P:
                newnode = node_of_ty(BLOCK_COPY);
                break;

            default:
                printerr("I don't yet know how to process block type %s\n".printf(block_type.to_string()));
                newnode = node_of_ty(BLOCK_COPY);
                break;
            }

            if(newnode != null) {
                self.node_.append((owned)newnode);  // clears newnode
                self.node_ = self.node_.last_child();
            }

            return 0;
        }

        /** md4c callback */
        private static int leave_block_(BlockType block_type, void *detail, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            --self.depth_;
            print("%sLeaving block %s\n",
                self.indent_, block_type.to_string());

            // Pop out of the last span, if we're in one
            if(self.node_.data.is_span) {
                self.node_ = self.node_.parent;
            }

            // TODO? check here that the block we are leaving has the type we expect?

            // Leave the current block
            self.node_ = self.node_.parent;

            return 0;
        }

        /** md4c callback */
        private static int enter_span_(SpanType span_type, void *detail, void *userdata)
        {
            GLib.Node<Elem> newnode = null;

            var self = (MarkdownMd4cReader)userdata;
            print("%sGot span %s ... ",
                self.indent_, span_type.to_string());

            switch(span_type) {
            case EM: newnode = node_of_ty(SPAN_EM); break;
            case STRONG: newnode = node_of_ty(SPAN_STRONG); break;
            case A:
                printerr("Hyperlinks are not yet supported\n");
                newnode = node_of_ty(SPAN_PLAIN);
                break;
            case IMG:
                printerr("Images are not yet supported\n");
                newnode = node_of_ty(SPAN_PLAIN);
                break;
            case CODE: newnode = node_of_ty(SPAN_CODE); break;
            case DEL: newnode = node_of_ty(SPAN_STRIKE); break;
            case U: newnode = node_of_ty(SPAN_UNDERLINE); break;
            default:
                printerr("Unsupported span type %s\n".printf(span_type.to_string()));
                newnode = node_of_ty(SPAN_PLAIN);
                break;
            }

            if(newnode != null) {
                self.node_.append((owned)newnode);  // clears newnode
                self.node_ = (GLib.Node<Elem>)self.node_.last_child();
            }
            return 0;
        }

        /** md4c callback */
        private static int leave_span_(SpanType span_type, void *detail, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            print("left span %s\n", span_type.to_string());

            // Move back into the parent span
            self.node_ = self.node_.parent;

            return 0;
        }

        /**
         * md4c callback to accept text content.
         *
         * Every text chunk gets its own Elem.Type.SPAN_PLAIN.  This is so
         * that text after a child span will not be merged with text
         * before the child span.
         */
        private static int text_(TextType text_type, /*const*/ Char? text, Size size, void *userdata)
        {
            var self = (MarkdownMd4cReader)userdata;
            var data = strndup((char *)text, size);
            print("%s<<%s>>\n", self.indent_, data);

            var newnode = node_of_ty(SPAN_PLAIN);
            newnode.data.text = data;
            self.node_.append((owned)newnode);  // clears newnode

            return 0;
        }

        // === Parser callbacks and data ===================================

        /**
         * Read a file and build a node tree for it.
         *
         * Fills in root_.
         */
        private void make_tree_for(string filename) throws FileError, MarkupError
        {
            // Read it in
            string contents;
            FileUtils.get_contents(filename, out contents);

            // Set up the parse

            root_ = node_of_ty(Elem.Type.ROOT);
            depth_ = 0;

            // Processing functions.  NOTE: no closure in the current binding.

            Md4c.Parser parser = new Parser();
            parser.enter_block = enter_block_;
            parser.leave_block = leave_block_;
            parser.enter_span = enter_span_;
            parser.leave_span = leave_span_;
            parser.text = text_;
            parser.debug_log = null;

            // Parse it
            var ok = Md4c.parse((Char?)contents, contents.length, parser, this);
            if(ok != 0) {
                throw new MarkupError.PARSE("parse failed (%d)".printf(ok));
            }
        }
    }
} // My
