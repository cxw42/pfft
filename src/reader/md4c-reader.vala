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
         * @param   filename    The file to read
         * @return A node tree of the document
         */
        public Doc read_document(string filename) throws FileError, MarkupError
        {
            // Read it in
            string contents;
            FileUtils.get_contents(filename, out contents);
            return read_string(contents);
        }

        /**
         * Produce a document for a string.
         * @param   contents    The string to parse
         * @return A node tree of the document
         */
        public Doc read_string(string contents) throws MarkupError
        {
            make_tree_for(contents);
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

        /** Tag for special blocks */
        private static string SBTAG = "pfft:";

        /**
         * md4c callback for entering blocks.
         *
         * Sets node_ to a SPAN_PLAIN if the block was of a recognized type.
         */
        private static int enter_block_(BlockType block_type, void *detail, void *userdata)
        {
            GLib.Node<Elem> newnode = null;

            var self = (MarkdownMd4cReader)userdata;
            llog("%sGot block %s",
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
                var infostr = get_info_string(detail);
                infostr._chomp();

                // Check for a special block
                if(substr(infostr, 0, SBTAG.length) == SBTAG) {
                    newnode = node_of_ty(BLOCK_SPECIAL);

                    var command = substr(infostr, SBTAG.length);
                    if(command == null) {
                        command = "";
                    } else {
                        command._strip();
                    }

                    if(command == "") {
                        lwarningo(newnode, "Special block with no command after '%s'", SBTAG);
                    }

                    newnode.data.info_string = command;

                } else {    // normal code block
                    newnode = node_of_ty(BLOCK_CODE);
                    newnode.data.info_string = infostr;
                }
                llogo(newnode, "%s, info string -%s-", newnode.data.ty.to_string(),
                    newnode.data.info_string);
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
            llog("%sLeaving block %s",
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
            llog("%sGot span %s ... ",
                self.indent_, span_type.to_string());

            switch(span_type) {
            case EM: newnode = node_of_ty(SPAN_EM); break;
            case STRONG: newnode = node_of_ty(SPAN_STRONG); break;
            case A:
                printerr("Hyperlinks are not yet supported\n");
                newnode = node_of_ty(SPAN_PLAIN);
                break;
            case IMG:
                newnode = node_of_ty(SPAN_IMAGE);
                string href, title;
                get_img_detail(detail, out href, out title);
                newnode.data.href = href;
                newnode.data.info_string = title;
                llog("%sImage href=`%s', title=`%s'", self.indent_, href, title);
                break;
            case CODE: newnode = node_of_ty(SPAN_CODE); break;
            case DEL: newnode = node_of_ty(SPAN_STRIKE); break;
            case SpanType.U: newnode = node_of_ty(SPAN_UNDERLINE); break;
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
            llog("%sleft span %s", self.indent_, span_type.to_string());

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
            llog("%s<<%s>>", self.indent_, data);

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
        private void make_tree_for(string contents) throws MarkupError
        {
            // Set up the parse

            root_ = node_of_ty(Elem.Type.ROOT);
            depth_ = 0;

            // Processing functions.  NOTE: no closure in the current binding.

            Md4c.Parser parser = new Parser();
            parser.flags = Dialect.GitHub | UNDERLINE;
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
