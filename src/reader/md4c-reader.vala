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
     * TODO merge with src/logging/strings.vala:pfft_strnlen()
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

        // === Internal helpers ============================================

        private delegate string NodeRenderer(GLib.Node<Elem> node);

        private static string render_as_plain_(GLib.Node<Elem> node)
        {
            return node.data.text;
        }

        /**
         * Render a node tree inside a fenced block as markdown.
         *
         * For use in {leave_block_}.
         *
         * NOTE: this assumes that special blocks only have spans in them.
         *
         * @param node      The node to render
         * @return The resulting markdown source.
         */
        private static string render_as_markdown_(GLib.Node<Elem> node)
        {
            var sb = new StringBuilder();
            var elem = node.data;

            switch(elem.ty) {
            case SPAN_PLAIN: sb.append(elem.text); break;
            case SPAN_EM: sb.append_printf("*%s*", elem.text); break;
            case SPAN_STRONG: sb.append_printf("**%s**", elem.text); break;
            case SPAN_CODE: sb.append_printf("`%s`", elem.text); break;
            case SPAN_STRIKE: sb.append_printf("~%s~", elem.text); break;
            case SPAN_UNDERLINE: sb.append_printf("_%s_", elem.text); break;
            case SPAN_IMAGE:
                if(elem.info_string != null && elem.info_string != "") {
                    sb.append_printf("![](%s \"%s\")", elem.text, elem.info_string);
                } else {
                    sb.append_printf("![](%s)", elem.text);
                }
                break;
            default:
                lwarningo(node, "Unknown type %s", elem.ty.to_string());
                break;
            }

            return sb.str;
        }

        /**
         * Render a node's children as text.
         */
        private static string render_kids_as_(GLib.Node<Elem> node, NodeRenderer renderer)
        {
            var sb = new StringBuilder();
            ltraceo(node, "%s", node.data.ty.to_string());
            node.children_foreach(ALL, (kid)=> {
                sb.append(render_node_(kid, renderer));
            });
            return sb.str;
        }

        private static string render_node_(GLib.Node<Elem> node, NodeRenderer renderer)
        {
            ltraceo(node, "%s: ---%s---", node.data.ty.to_string(), node.data.text);

            return renderer(node) + render_kids_as_(node, renderer);
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
                if(infostr.has_prefix(SBTAG)) {
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

            case HTML:
                newnode = node_of_ty(BLOCK_SPECIAL);
                newnode.data.info_string = INFOSTR_HTML;
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

            // Postprocess special blocks
            if(self.node_.data.ty == BLOCK_SPECIAL &&
                self.node_.data.info_string == INFOSTR_HTML) {

                // For now, drop HTML.

                string inner_contents = render_kids_as_(self.node_, render_as_plain_);
                inner_contents._strip();

                // If the text isn't a single HTML comment, warn that we're
                // dropping it.  It's a single HTML comment unless: it doesn't
                // start with a start-comment marker, it doesn't end with an
                // end-comment marker, or there's an end-comment marker before
                // the end of the string.
                if(substr(inner_contents, 0,4) != "<!--" ||
                    substr(inner_contents, -3) != "-->" ||
                    inner_contents.index_of("-->") != inner_contents.length - 3
                ) {

                    lwarningo(self.node_, "Ignoring HTML block:\n%s\n",
                        self.node_.data.as_string());
                    lmemdumpo(self.node_, "Block contents", inner_contents,
                        inner_contents.length);
                }

                self.node_.data.info_string = INFOSTR_NOP;
                self.node_.children_foreach(ALL, (kid)=>{ kid.unlink(); });

            } else if(self.node_.data.ty == BLOCK_SPECIAL) {
                do { // once
                    // Render the block's contents back to Markdown.
                    // This is easy because special blocks are code blocks,
                    // which contain only text.
                    string inner_contents = render_kids_as_(self.node_, render_as_markdown_);
                    ltraceo(self.node_, "inner_contents: ---%s---", inner_contents);

                    // Parse the Markdown
                    var inner_reader = new MarkdownMd4cReader();
                    // TODO copy reader options from this to inner_reader

                    Doc inner_doc = null;
                    try {
                        inner_doc = inner_reader.read_string(inner_contents);
                    } catch(MarkupError e) {
                        lwarningo(self.node_,
                            "Could not parse special block's contents as Markdown: %s",
                            e.message);
                        break;
                    }
                    ltraceo(self.node_,"Got inner doc:\n%s\n", inner_doc.as_string());

                    // Replace the special block's children with the results
                    // of parsing the inner text
                    self.node_.children_foreach(ALL, (kid)=>{ kid.unlink(); });
                    inner_doc.root.children_foreach(ALL, (kid)=>{
                        unowned var kidnode = (GLib.Node<Elem>)kid;
                        ltraceo(kidnode, "Existing node of type %s ---%s---",
                        kidnode.data.ty.to_string(), kidnode.data.text);

                        GLib.Node<Elem> newnode = kidnode.copy_deep((e)=>{
                            return e.clone();
                        });
                        ltraceo(newnode, "New node of type %s ---%s---",
                        newnode.data.ty.to_string(), newnode.data.text);

                        self.node_.append((owned)newnode);
                    });
                } while(false);
            }

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

        // === Parser invoker ==============================================

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
