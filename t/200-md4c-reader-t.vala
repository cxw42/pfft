// t/200-md4c-reader-t.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// TODO find or write a deep-comparison library for Vala!

using My;

// === Helpers =============================================================

/** A lambda that checks the contents of a document */
delegate void DocChecker(Doc doc) throws FileError, GLib.MarkupError;

/** A lambda that checks the contents of a node */
delegate void NodeChecker(GLib.Node<Elem> node);

/**
 * Read a file, or parse a string, and test the resulting document.
 *
 * Common code for other test functions that pass if the file loads correctly.
 * @param   text        Text (see is_contents, below)
 * @param   checker     Lambda to check the resulting document
 * @param   is_contents If false, text is a filename with respect to the same
 *                      directory as this file.
 *                      If true, text is the contents themselves.
 */
void read_and_test(string text, DocChecker checker, bool is_contents = false)
{
    bool did_load = false;
    try {
        var md = new MarkdownMd4cReader();
        Doc doc;
        if(is_contents) {
            doc = md.read_string(text);
        } else {
            var filepath = Test.build_filename(Test.FileType.DIST, text);
            Test.message("Loading filename %s", filepath);
            doc = md.read_document(filepath);
        }
        assert_nonnull(doc);
        did_load = true;

        Test.message("Got doc:\n%s\n", as_diag(doc.as_string()));

        checker(doc);

    } catch(FileError e) {  // LCOV_EXCL_START - unreached if tests pass
        warning("file error: %s", e.message);
        assert_not_reached();
    } catch(GLib.MarkupError e) {
        warning("%s", e.message);
        assert_not_reached();
    }   // LCOV_EXCL_STOP
    assert_true(did_load);
}

/** Default NodeChecker */
private void default_node_checker(GLib.Node<Elem> node)
{
    // nop
}

/**
 * Parse a string that contains exactly one block, and check its children
 * @param   text            See is_contents
 * @param   is_contents     If false, text is a filename with respect to the
 *                          same directory as this file.
 *                          If true, text is the contents themselves.
 * @param   block_type      What type the block must be
 * @param   span_type       What type the span must be
 * @param   block_checker   Function to check the block
 * @param   span_checker    Function to check the span
 */
void test_block_span(string text, bool is_contents,
    Elem.Type block_type, Elem.Type span_type,

    NodeChecker block_checker = default_node_checker,
    NodeChecker span_checker = default_node_checker)
{
    read_and_test(text, (doc)=> {
        unowned GLib.Node<Elem> node0 = doc.root.nth_child(0);
        assert_true(node0.n_children() >= 1);
        assert_true(node0.data.ty == block_type);
        block_checker(node0);
        unowned GLib.Node<Elem> node1 = node0.nth_child(0);
        assert_true(node1.n_children() < 2);
        assert_true(node1.data.ty == span_type);
        span_checker(node1);
    }, is_contents);
}
// === General tests =======================================================

void test_misc()
{
    var md = new MarkdownMd4cReader();
    assert_true(!md.meta);  // for coverage
}

void test_loadfile()
{
    read_and_test("basic.md", (doc)=> {
        assert_true(doc.root.n_children() == 2);

        unowned GLib.Node<Elem> node0 = doc.root.nth_child(0);
        assert_true(node0.n_children() == 1);
        assert_true(node0.data.ty == Elem.Type.BLOCK_HEADER);
        unowned GLib.Node<Elem> node1 = node0.nth_child(0);
        assert_true(node1.n_children() == 0);
        assert_true(node1.data.ty == Elem.Type.SPAN_PLAIN);
        assert_true(node1.data.text == "Header");

        unowned GLib.Node<Elem> node2 = doc.root.nth_child(1);
        assert_true(node2.n_children() == 1);
        assert_true(node2.data.ty == Elem.Type.BLOCK_COPY);
        unowned GLib.Node<Elem> node3 = node2.nth_child(0);
        assert_true(node3.n_children() == 0);
        assert_true(node3.data.ty == Elem.Type.SPAN_PLAIN);
        assert_true(node3.data.text == "Body");
    });
}

#if 0
// TODO figure out how to trigger an md4c parse error
void test_image_bad()
{
    read_and_test("![](", (doc)=>{assert_not_reached();}, true);
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "200-image-bad.md");
        Test.message("Loading filename %s", fn);

        var md = new MarkdownMd4cReader();
        Doc doc = md.read_document(fn);
        doc = null; // LCOV_EXCL_LINE - never happens if tests pass
        assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass

    } catch(FileError e) {  // LCOV_EXCL_START - unreached if tests pass
        warning("file error: %s", e.message);
        assert_not_reached();
    } catch(GLib.MarkupError e) {
        warning("%s", e.message);
        assert_true(e is GLib.MarkupError.PARSE);
    }   // LCOV_EXCL_STOP
}
#endif

// === Tests of specific elements ==========================================
// These are in order of Elem.Type.

void test_header()
{
    test_block_span("# H1", true, BLOCK_HEADER, SPAN_PLAIN,
        (bnode)=> { assert_true(bnode.data.header_level == 1); },
        (snode)=> { assert_true(snode.data.text == "H1"); }
    );
}

void test_quote()
{
    read_and_test("> Raven", (doc)=> {
        unowned GLib.Node<Elem> node0 = doc.root.nth_child(0);
        assert_true(node0.n_children() >= 1);
        assert_true(node0.data.ty == Elem.Type.BLOCK_QUOTE);
        assert_true(node0.data.info_string == "");
        unowned GLib.Node<Elem> node1 = node0.nth_child(0);
        assert_true(node1.n_children() == 1);
        assert_true(node1.data.ty == Elem.Type.BLOCK_COPY);
        unowned GLib.Node<Elem> node2 = node1.nth_child(0);
        assert_true(node2.n_children() == 0);
        assert_true(node2.data.ty == Elem.Type.SPAN_PLAIN);
        assert_true(node2.data.text == "Raven");
    }, true);
}

// TODO ul, ol, li, hr

void test_codeblock()
{
    test_block_span("200-codeblock.md", false, BLOCK_CODE, SPAN_PLAIN,
        (bnode)=> { assert_true(bnode.data.info_string == ""); },
        (snode)=> {
        assert_true(substr(snode.data.text, 0, "Line 1".length) == "Line 1");
    }
    );
}

void test_special()
{
    test_block_span("200-special.md", false, BLOCK_SPECIAL, SPAN_PLAIN,
        (bnode)=> { assert_true(bnode.data.info_string == "specialblock"); },
        (snode)=> { assert_true(snode.data.text == "Hello"); }
    );
}

void test_special_nocmd()
{
    test_block_span("200-special-nocmd.md", false, BLOCK_SPECIAL, SPAN_PLAIN,
        (bnode)=> { assert_true(bnode.data.info_string == ""); },
        (snode)=> { assert_true(snode.data.text == "No command"); }
    );
}

// span_plain is tested plenty of places herein

void test_italics()
{
    test_block_span("*Italics*", true, BLOCK_COPY, SPAN_EM,
        default_node_checker,
        (snode)=>{
        assert_true(snode.n_children() == 1);
        unowned GLib.Node<Elem> node1 = snode.nth_child(0);
        assert_true(node1.n_children() == 0);
        assert_true(node1.data.ty == SPAN_PLAIN);
        assert_true(node1.data.text == "Italics");
    }
    );
}

void test_bold()
{
    test_block_span("**Bold**", true, BLOCK_COPY, SPAN_STRONG,
        default_node_checker,
        (snode)=>{
        assert_true(snode.n_children() == 1);
        unowned GLib.Node<Elem> node1 = snode.nth_child(0);
        assert_true(node1.n_children() == 0);
        assert_true(node1.data.ty == SPAN_PLAIN);
        assert_true(node1.data.text == "Bold");
    }
    );
}

void test_inline_code()
{
    test_block_span("`31337`", true, BLOCK_COPY, SPAN_CODE,
        default_node_checker,
        (snode)=>{
        assert_true(snode.n_children() == 1);
        unowned GLib.Node<Elem> node1 = snode.nth_child(0);
        assert_true(node1.n_children() == 0);
        assert_true(node1.data.ty == SPAN_PLAIN);
        assert_true(node1.data.text == "31337");
    }
    );
}

void test_strike()
{
    test_block_span("~not really~", true, BLOCK_COPY, SPAN_STRIKE,
        default_node_checker,
        (snode)=>{
        assert_true(snode.n_children() == 1);
        unowned GLib.Node<Elem> node1 = snode.nth_child(0);
        assert_true(node1.n_children() == 0);
        assert_true(node1.data.ty == SPAN_PLAIN);
        assert_true(node1.data.text == "not really");
    }
    );
}

void test_underline()
{
    test_block_span("_NZ_", true, BLOCK_COPY, SPAN_UNDERLINE,
        default_node_checker,
        (snode)=>{
        assert_true(snode.n_children() == 1);
        unowned GLib.Node<Elem> node1 = snode.nth_child(0);
        assert_true(node1.n_children() == 0);
        assert_true(node1.data.ty == SPAN_PLAIN);
        assert_true(node1.data.text == "NZ");
    }
    );
}

void test_image()
{
    NodeChecker scheck = (snode)=>{assert_true(snode.data.href == "image.png");};
    test_block_span("200-image.md", false, BLOCK_COPY, SPAN_IMAGE,
        default_node_checker, scheck);
    test_block_span("![](image.png)", true, BLOCK_COPY, SPAN_IMAGE,
        default_node_checker, scheck);
}

public static int main (string[] args)
{
    // run the tests
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/200-md4c-reader/misc", test_misc);
    Test.add_func("/200-md4c-reader/loadfile", test_loadfile);
#if 0
    Test.add_func("/200-md4c-reader/image_bad", test_image_bad);
#endif
    Test.add_func("/200-md4c-reader/header", test_header);
    Test.add_func("/200-md4c-reader/quote", test_quote);
    Test.add_func("/200-md4c-reader/codeblock", test_codeblock);
    Test.add_func("/200-md4c-reader/special", test_special);
    Test.add_func("/200-md4c-reader/special_nocmd", test_special_nocmd);
    Test.add_func("/200-md4c-reader/italics", test_italics);
    Test.add_func("/200-md4c-reader/bold", test_bold);
    Test.add_func("/200-md4c-reader/inline_code", test_inline_code);
    Test.add_func("/200-md4c-reader/strike", test_strike);
    Test.add_func("/200-md4c-reader/underline", test_underline);
    Test.add_func("/200-md4c-reader/image", test_image);

    return Test.run();
}
