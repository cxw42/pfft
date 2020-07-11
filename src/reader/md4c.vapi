// src/reader/md4c.vapi: Vala interface for
// https://github.com/mity/md4c
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//
// See md4c.h license at end

[CCode(cheader_filename="md4c.h", cprefix="MD_")]
namespace Md4c {

#if MD4C_USE_UTF16
    [SimpleType]
    [CCode (cname = "MD_CHAR", has_type_id = false)]
    public struct Char : uint16 { }
#else
    [SimpleType]
    [CCode (cname = "MD_CHAR", has_type_id = false)]
    public struct Char : char { }
#endif

    [SimpleType]
    [CCode (cname = "MD_SIZE", has_type_id = false)]
    public struct Size : uint { }

    [SimpleType]
    [CCode (cname = "MD_OFFSET", has_type_id = false)]
    public struct Offset : uint { }

    /**
     * Block represents a part of document hierarchy structure like a paragraph
     * or list item.
     */
    [CCode(cname="MD_BLOCKTYPE", cprefix="MD_BLOCK_", has_type_id=false)]
    public enum BlockType {
        /** <body>...</body> */
        DOC = 0,

        /** <blockquote>...</blockquote> */
        QUOTE,

        /**
         * <ul>...</ul>
         *
         * Detail: Structure MD_BLOCK_UL_DETAIL.
         */
        UL,

        /**
         * <ol>...</ol>
         *
         * Detail: Structure MD_BLOCK_OL_DETAIL.
         */
        OL,

        /**
         * <li>...</li>
         *
         * Detail: Structure MD_BLOCK_LI_DETAIL.
         */
        LI,

        /** <hr> */
        HR,

        /**
         * <h1>...</h1> (for levels up to 6)
         *
         * Detail: Structure MD_BLOCK_H_DETAIL.
         */
        H,

        /**
         * <pre><code>...</code></pre>
         *
         * Note the text lines within code blocks are terminated with '\n'
         * instead of explicit MD_TEXT_BR.
         */
        CODE,

        /**
         * Raw HTML block.
         *
         * This itself does not correspond to any particular HTML
         * tag. The contents of it _is_ raw HTML source intended to be put
         * in verbatim form to the HTML output.
         */
        HTML,

        /** <p>...</p> */
        P,

        /**
         * <table>...</table> and its contents.
         *
         * Detail: Structure MD_BLOCK_TD_DETAIL (used with MD_BLOCK_TH and MD_BLOCK_TD)
         * Note all of these are used only if extension MD_FLAG_TABLES is enabled.
         */
        TABLE,
        THEAD,
        TBODY,
        TR,
        TH,
        TD,
    }

    /**
     * Span represents an in-line piece of a document which should be rendered with
     * the same font, color and other attributes.
     *
     * A sequence of spans forms a block like paragraph or list item.
     */
    [CCode(cname="MD_SPANTYPE", cprefix="MD_SPAN_", has_type_id = false)]
    public enum SpanType {
        /** <em>...</em> */
        EM,

        /** <strong>...</strong> */
        STRONG,

        /**
         * <a href="xxx">...</a>
         *
         * Detail: Structure MD_SPAN_A_DETAIL.
         */
        A,

        /**
         * <img src="xxx">...</a>
         *
         * Detail: Structure MD_SPAN_IMG_DETAIL.
         * Note: Image text can contain nested spans and even nested images.
         * If rendered into ALT attribute of HTML <IMG> tag, it's responsibility
         * of the renderer to deal with it.
         */
        IMG,

        /** <code>...</code> */
        CODE,

        /**
         * <del>...</del>
         *
         * Note: Recognized only when MD_FLAG_STRIKETHROUGH is enabled.
         */
        DEL,

        /**
         * For recognizing inline ($) and display ($$) equations
         *
         * Note: Recognized only when MD_FLAG_LATEXMATHSPANS is enabled.
         */
        LATEXMATH,
        LATEXMATH_DISPLAY,

        /**
         * Wiki links
         *
         * Note: Recognized only when MD_FLAG_WIKILINKS is enabled.
         */
        WIKILINK,

        /**
         * <u>...</u>
         *
         * Note: Recognized only when MD_FLAG_UNDERLINE is enabled.
         */
        U
    }

    /** Text is the actual textual contents of span. */
    [CCode(cname="MD_TEXTTYPE", cprefix="MD_TEXT_", has_type_id = false)]
    public enum TextType {
        /** Normal text. */
        NORMAL = 0,

        /**
         * NULL character.
         *
         * CommonMark requires replacing NULL character with
         * the replacement char U+FFFD, so this allows caller to do that easily.
         */
        NULLCHAR,

        /* Line breaks.
         * Note these are not sent from blocks with verbatim output (MD_BLOCK_CODE
         * or MD_BLOCK_HTML). In such cases, '\n' is part of the text itself. */

        /** <br> (hard break) */
        BR,
        /** '\n' in source text where it is not semantically meaningful (soft break) */
        SOFTBR,

        /**
         * Entity.
         *
         * (a) Named entity, e.g. &nbsp;
         * (Note MD4C does not have a list of known entities.
         * Anything matching the regexp /&[A-Za-z][A-Za-z0-9]{1,47};/ is
         * treated as a named entity.)
         *
         * (b) Numerical entity, e.g. &#1234;
         *
         * (c) Hexadecimal entity, e.g. &#x12AB;
         *
         * As MD4C is mostly encoding agnostic, application gets the verbatim
         * entity text into the MD_RENDERER::text_callback().
         */
        ENTITY,

        /**
         * Text in a code block (inside MD_BLOCK_CODE) or inlined code (`code`).
         *
         * If it is inside MD_BLOCK_CODE, it includes spaces for indentation and
         * '\n' for new lines. MD_TEXT_BR and MD_TEXT_SOFTBR are not sent for this
         * kind of text.
         */
        CODE,

        /**
         * Text is a raw HTML.
         *
         * If it is contents of a raw HTML block (i.e. not an inline raw HTML),
         * then MD_TEXT_BR and MD_TEXT_SOFTBR are not used.  The text contains
         * verbatim '\n' for the new lines.
         */
        HTML,

        /**
         * Text is inside an equation.
         *
         * This is processed the same way as inlined code spans (`code`).
         */
        LATEXMATH
    }

    /** Alignment enumeration. */
    [CCode(cname="MD_ALIGN", cprefix="MD_ALIGN_", has_type_id = false)]
    public enum Align {
        /** When unspecified. */
        DEFAULT = 0,
        LEFT,
        CENTER,
        RIGHT
    }

    /**
     * String attribute.
     *
     * This wraps strings which are outside of a normal text flow and which are
     * propagated within various detailed structures, but which still may contain
     * string portions of different types like e.g. entities.
     *
     * So, for example, lets consider an image has a title attribute string
     * set to "foo &quot; bar". (Note the string size is 14.)
     *
     * Then the attribute MD_SPAN_IMG_DETAIL::title shall provide the following:
     * * [0]: "foo "   (substr_types[0] == MD_TEXT_NORMAL; substr_offsets[0] == 0)
     * * [1]: "&quot;" (substr_types[1] == MD_TEXT_ENTITY; substr_offsets[1] == 4)
     * * [2]: " bar"   (substr_types[2] == MD_TEXT_NORMAL; substr_offsets[2] == 10)
     * * [3]: (n/a)    (n/a                              ; substr_offsets[3] == 14)
     *
     * Note that these conditions are guaranteed:
     * * substr_offsets[0] == 0
     * * substr_offsets[LAST+1] == size
     * * Only MD_TEXT_NORMAL, MD_TEXT_ENTITY, MD_TEXT_NULLCHAR substrings can appear.
     */
    [CCode(cname="MD_ATTRIBUTE", has_type_id = false, destroy_function="OOPS_MD_ATTRIBUTE_IS_ALWAYS_UNOWNED")]
    public struct Attribute {
        public const /*unowned*/ Char ? text;
        public Size size;
        public const /*unowned*/ TextType ? substr_types;
        public const /*unowned*/ Offset ? substr_offsets;
    }


    /** Detailed info for MD_BLOCK_UL. */
    [CCode(cname="MD_BLOCK_UL_DETAIL", has_type_id = false, destroy_function="OOPS_MD_BLOCK_UL_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct BlockULDetail {
        /** Non-zero if tight list, zero if loose. */
        public int is_tight;
        /** Item bullet character in MarkDown source of the list, e.g. '-', '+', '*'. */
        public Char mark;
    }

    /** Detailed info for MD_BLOCK_OL. */
    [CCode(cname="MD_BLOCK_OL_DETAIL", has_type_id = false, destroy_function="OOPS_MD_BLOCK_OL_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct BlockOLDetail {
        /** Start index of the ordered list. */
        public uint start;
        /** Non-zero if tight list, zero if loose. */
        public int is_tight;
        /** Character delimiting the item marks in MarkDown source, e.g. '.' or ')' */
        public Char mark_delimiter;
    }

    /** Detailed info for MD_BLOCK_LI. */
    [CCode(cname="MD_BLOCK_LI_DETAIL", has_type_id = false, destroy_function="OOPS_MD_BLOCK_LI_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct BlockLIDetail {
        /** Can be non-zero only with MD_FLAG_TASKLISTS */
        public int is_task;
        /** If is_task, then one of 'x', 'X' or ' '. Undefined otherwise. */
        public Char task_mark;
        /** If is_task, then offset in the input of the char between '[' and ']'. */
        public Offset task_mark_offset;
    }

    /** Detailed info for MD_BLOCK_H. */
    [CCode(cname="MD_BLOCK_H_DETAIL", has_type_id = false, destroy_function="OOPS_MD_BLOCK_H_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct BlockHDetail {
        /** Header level (1 - 6) */
        public uint level;
    }

    /** Detailed info for MD_BLOCK_CODE. */
    [CCode(cname="MD_BLOCK_CODE_DETAIL", has_type_id = false, destroy_function="OOPS_MD_BLOCK_CODE_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct BlockCodeDetail {
        public Attribute info;
        public Attribute lang;
        /** The character used for fenced code block; or zero for indented code block. */
        public Char fence_char;
    }

    /** Detailed info for MD_BLOCK_TH and MD_BLOCK_TD. */
    [CCode(cname="MD_BLOCK_TD_DETAIL", has_type_id = false, destroy_function="OOPS_MD_BLOCK_TD_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct BlockTDDetail {
        public Align align;
    }

    /** Detailed info for MD_SPAN_A. */
    [CCode(cname="MD_SPAN_A_DETAIL", has_type_id = false, destroy_function="OOPS_MD_SPAN_A_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct SpanADetail {
        public Attribute href;
        public Attribute title;
    }

    /** Detailed info for MD_SPAN_IMG. */
    [CCode(cname="MD_SPAN_IMG_DETAIL", has_type_id = false, destroy_function="OOPS_MD_SPAN_IMG_DETAIL_IS_ALWAYS_UNOWNED")]
    public struct SpanImgDetail {
        public Attribute src;
        public Attribute title;
    }

    /** Detailed info for MD_SPAN_WIKILINK. */
    [CCode(cname="MD_SPAN_WIKILINK", has_type_id = false, destroy_function="OOPS_MD_SPAN_WIKILINK_IS_ALWAYS_UNOWNED")]
    public struct SpanWikiLink {
        public Attribute target;
    }

    /**
     * Flags specifying extensions/deviations from CommonMark specification.
     *
     * By default (when MD_RENDERER::flags == 0), we follow CommonMark specification.
     * The following flags may allow some extensions or deviations from it.
     */
    [CCode(cname="unsigned int", cprefix="MD_FLAG_", has_type_id = false)]
    [Flags]
    public enum Flags {
        COLLAPSEWHITESPACE,         /* In MD_TEXT_NORMAL, collapse non-trivial whitespace into single ' ' */
        PERMISSIVEATXHEADERS,       /* Do not require space in ATX headers ( ###header ) */
        PERMISSIVEURLAUTOLINKS,     /* Recognize URLs as autolinks even without '<', '>' */
        PERMISSIVEEMAILAUTOLINKS,   /* Recognize e-mails as autolinks even without '<', '>' and 'mailto:' */
        NOINDENTEDCODEBLOCKS,       /* Disable indented code blocks. (Only fenced code works.) */
        NOHTMLBLOCKS,               /* Disable raw HTML blocks. */
        NOHTMLSPANS,                /* Disable raw HTML (inline). */
        /** Do not use --- here so that the bit values of the flags will be correct. */
        [CCode(cname="OOPS_NONEXISTENT_MD_FLAG_0080")]
        NONEXISTENT_0080,
        TABLES,       /* Enable tables extension. */
        STRIKETHROUGH,        /* Enable strikethrough extension. */
        PERMISSIVEWWWAUTOLINKS,       /* Enable WWW autolinks (even without any scheme prefix, if they begin with 'www.') */
        TASKLISTS,        /* Enable task list extension. */
        LATEXMATHSPANS,       /* Enable $ and $$ containing LaTeX equations. */
        WIKILINKS,        /* Enable wiki links extension. */
        UNDERLINE,        /* Enable underline extension (and disables '_' for normal emphasis). */
    }

    /** (MD_FLAG_PERMISSIVEEMAILAUTOLINKS | MD_FLAG_PERMISSIVEURLAUTOLINKS | MD_FLAG_PERMISSIVEWWWAUTOLINKS) */
    [CCode(cname="MD_FLAG_PERMISSIVEAUTOLINKS")]
    public const Flags PERMISSIVEAUTOLINKS;

    /** (MD_FLAG_NOHTMLBLOCKS | MD_FLAG_NOHTMLSPANS) */
    [CCode(cname="MD_FLAG_NOHTML")]
    public const Flags NOHTML;

    /**
     * Convenient sets of flags corresponding to well-known Markdown dialects.
     *
     * Note we may only support subset of features of the referred dialect.
     * The constant just enables those extensions which bring us as close as
     * possible given what features we implement.
     *
     * ABI compatibility note: Meaning of these can change in time as new
     * extensions, bringing the dialect closer to the original, are implemented.
     */
    namespace Dialect {
        /** Default Markdown dialect */
        [CCode(cname="MD_DIALECT_COMMONMARK")]
        public const Flags CommonMark;

        /**
         * GitHub-flavored Markdown.
         *
         * (MD_FLAG_PERMISSIVEAUTOLINKS | MD_FLAG_TABLES | MD_FLAG_STRIKETHROUGH | MD_FLAG_TASKLISTS)
         */
        [CCode(cname="MD_DIALECT_GITHUB")]
        public const Flags GitHub;
    }

    /**
     * Callback function for blocks.
     *
     * This does not exist in the C header for MD4C.
     */
    [CCode(has_target = false)]
    public delegate int BlockCallback(BlockType block_type, void *detail, void *userdata);

    /**
     * Callback function for spans.
     *
     * This does not exist in the C header for MD4C.
     */
    [CCode(has_target = false)]
    public delegate int SpanCallback(SpanType span_type, void *detail, void *userdata);

    /**
     * Callback function for text.
     *
     * This does not exist in the C header for MD4C.
     */
    [CCode(has_target = false)]
    public delegate int TextCallback(TextType text_type, /*const*/ Char ? text, Size size, void *userdata);

    /**
     * Callback function for debugging.
     *
     * This does not exist in the C header for MD4C.
     */
    [CCode(has_target = false)]
    public delegate int DebugCallback(/*const*/ string ? msg, void *userdata);

    /**
     * Callback function for the unused syntax callback.
     *
     * This does not exist in the C header for MD4C.
     */
    [CCode(has_target=false)]
    public delegate int VoidCallback();

    /**
     * Renderer structure.
     *
     * TODO figure out how to use delegates for this.
     * The constructor and free_function are defined in md4c-shim.c.
     */
    [CCode(cname="MD_PARSER", free_function="md4c_free_parser_", cheader_filename="md4c-shim.h")]
    [Compact]
    public class Parser {

        [CCode(cname="md4c_new_parser_")]
        public Parser();

        /** Reserved. Set to zero. */
        protected uint abi_version;

        /** Dialect options. Bitmask of MD_FLAG_xxxx values. */
        public Flags flags;

        /**
         * Caller-provided rendering callbacks.
         *
         * For some block/span types, more detailed information is provided in a
         * type-specific structure pointed by the argument 'detail'.
         *
         * The last argument of all callbacks, 'userdata', is just propagated from
         * md_parse() and is available for any use by the application.
         *
         * Note any strings provided to the callbacks as their arguments or as
         * members of any detail structure are generally not zero-terminated.
         * Application has take the respective size information into account.
         *
         * Callbacks may abort further parsing of the document by returning non-zero.
         */
        public unowned BlockCallback enter_block;
        public unowned BlockCallback leave_block;

        public unowned SpanCallback enter_span;
        public unowned SpanCallback leave_span;

        public unowned TextCallback text;

        /**
         * Debug callback. Optional (may be NULL).
         *
         * If provided and something goes wrong, this function gets called.
         * This is intended for debugging and problem diagnosis for developers;
         * it is not intended to provide any errors suitable for displaying to an
         * end user.
         */
        public unowned DebugCallback debug_log;

        /** Reserved.  Set to NULL. */
        public unowned VoidCallback syntax;

    }

    /* For backward compatibility. Do not use in new code. */
    // typedef MD_PARSER MD_RENDERER;

    /**
     * Parse the Markdown document stored in the string 'text' of size 'size'.
     *
     * The renderer provides callbacks to be called during the parsing so the
     * caller can render the document on the screen or convert the Markdown
     * to another format.
     *
     * Zero is returned on success. If a runtime error occurs (e.g. a memory
     * fails), -1 is returned. If the processing is aborted due any callback
     * returning non-zero, md_parse() the return value of the callback is returned.
     */
    [CCode(cname="md_parse")]
    public int parse(/*const*/ Char ? text, Size size, /*const*/ Parser ? parser, void *userdata);

}


// md4c.h copyright notice follows
/*
 * MD4C: Markdown parser for C
 * (http://github.com/mity/md4c)
 *
 * Copyright (c) 2016-2020 Martin Mitas
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
