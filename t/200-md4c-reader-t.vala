// t/200-md4c-reader-t.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// TODO find or write a deep-comparison library for Vala!

using My;
using My.Cmp;

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
 * Parse a string that contains exactly one block, and check its first child
 * @param   text            See is_contents
 * @param   is_contents     If false, text is a filename with respect to the
 *                          same directory as this file.
 *                          If true, text is the contents themselves.
 * @param   block_type      What type the block must be
 * @param   child_type      What type the child (usually a span) must be
 * @param   block_checker   Function to check the block
 * @param   child_checker   Function to check the child
 */
void test_block_child(string text, bool is_contents,
    Elem.Type block_type, Elem.Type child_type,

    NodeChecker block_checker = default_node_checker,
    NodeChecker child_checker = default_node_checker)
{
    diag(GLib.Log.METHOD);
    read_and_test(text, (doc)=> {
        unowned GLib.Node<Elem> node0 = doc.root.nth_child(0);
        assert_nonnull(node0);
        if(node0 == null) {
            return; // can't test anything else
        }
        assert_cmpuint(node0.n_children(), GLib.CompareOperator.GE, 1);
        assert_true(node0.data.ty == block_type);
        block_checker(node0);
        unowned GLib.Node<Elem> node1 = node0.nth_child(0);
        assert_nonnull(node1);
        if(node1 != null) {
            assert_cmpuint(node1.n_children(), GLib.CompareOperator.LT, 2);
            assert_true(node1.data.ty == child_type);
            child_checker(node1);
        }
    }, is_contents);
}

/**
 * Check for a single child span.
 *
 * For use in {NodeChecker} functions.
 */
void assert_has_one_span_child(GLib.Node<Elem> node, Elem.Type span_type,
    string span_text)
{
    assert_cmpuint(node.n_children(), GLib.CompareOperator.EQ, 1);
    unowned GLib.Node<Elem> snode = node.nth_child(0);
    assert_true(snode.data.ty == span_type);
    assert_true(snode.data.text == span_text);
    assert_cmpuint(snode.n_children(), GLib.CompareOperator.EQ, 0);
}

// === General tests =======================================================

void test_misc()
{
    diag(GLib.Log.METHOD);
    var md = new MarkdownMd4cReader();
    assert_true(!md.meta);  // for coverage
}

void test_loadfile()
{
    diag(GLib.Log.METHOD);
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
    diag(GLib.Log.METHOD);
    test_block_child("# H1", true, BLOCK_HEADER, SPAN_PLAIN,
        (bnode)=> { assert_true(bnode.data.header_level == 1); },
        (snode)=> { assert_true(snode.data.text == "H1"); }
    );
}

void test_quote()
{
    diag(GLib.Log.METHOD);
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
    diag(GLib.Log.METHOD);
    test_block_child("200-codeblock.md", false, BLOCK_CODE, SPAN_PLAIN,
        (bnode)=> { assert_true(bnode.data.info_string == ""); },
        (snode)=> { assert_true(substr(snode.data.text, 0, "Line 1".length) == "Line 1"); }
    );
}

void test_special()
{
    diag(GLib.Log.METHOD);
    test_block_child("200-special.md", false, BLOCK_SPECIAL, BLOCK_COPY,
        (bnode)=> { assert_true(bnode.data.info_string == "specialblock"); },
        (cnode)=> { assert_has_one_span_child(cnode, SPAN_PLAIN, "Hello"); }
    );
}

void test_special_nocmd()
{
    diag(GLib.Log.METHOD);
    test_block_child("200-special-nocmd.md", false, BLOCK_SPECIAL, BLOCK_COPY,
        (bnode)=> { assert_true(bnode.data.info_string == ""); },
        (cnode)=> {
        assert_has_one_span_child(cnode, SPAN_PLAIN, "No command");
    }
    );
}

void test_special_with_formatting()
{
    diag(GLib.Log.METHOD);
    test_block_child("```pfft:specialblock\n**Formatted**\n```", true,
        BLOCK_SPECIAL, BLOCK_COPY,
        (bnode)=> { assert_true(bnode.data.info_string == "specialblock"); },
        (copy_node)=> {
        assert_true(copy_node.n_children() == 1);
        unowned GLib.Node<Elem> snode = copy_node.nth_child(0);
        assert_true(snode.data.ty == SPAN_STRONG);
        assert_has_one_span_child(snode, SPAN_PLAIN, "Formatted");
    }
    );
}

// span_plain is tested plenty of places herein

void test_italics()
{
    diag(GLib.Log.METHOD);
    test_block_child("*Italics*", true, BLOCK_COPY, SPAN_EM,
        default_node_checker,
        (cnode)=>{ assert_has_one_span_child(cnode, SPAN_PLAIN, "Italics"); }
    );
}

void test_bold()
{
    diag(GLib.Log.METHOD);
    test_block_child("**Bold**", true, BLOCK_COPY, SPAN_STRONG,
        default_node_checker,
        (cnode)=>{ assert_has_one_span_child(cnode, SPAN_PLAIN, "Bold"); }
    );
}

void test_inline_code()
{
    diag(GLib.Log.METHOD);
    test_block_child("`31337`", true, BLOCK_COPY, SPAN_CODE,
        default_node_checker,
        (cnode)=>{ assert_has_one_span_child(cnode, SPAN_PLAIN, "31337"); }
    );
}

void test_strike()
{
    diag(GLib.Log.METHOD);
    test_block_child("~not really~", true, BLOCK_COPY, SPAN_STRIKE,
        default_node_checker,
        (cnode)=>{ assert_has_one_span_child(cnode, SPAN_PLAIN, "not really"); }
    );
}

void test_underline()
{
    diag(GLib.Log.METHOD);
    test_block_child("_NZ_", true, BLOCK_COPY, SPAN_UNDERLINE,
        default_node_checker,
        (cnode)=>{ assert_has_one_span_child(cnode, SPAN_PLAIN, "NZ"); }
    );
}

void test_image()
{
    diag(GLib.Log.METHOD);
    NodeChecker scheck = (snode)=>{assert_true(snode.data.href == "image.png");};
    test_block_child("200-image.md", false, BLOCK_COPY, SPAN_IMAGE,
        default_node_checker, scheck);
    test_block_child("![](image.png)", true, BLOCK_COPY, SPAN_IMAGE,
        default_node_checker, scheck);
}

void test_html_comment()
{
    diag(GLib.Log.METHOD);
    read_and_test("200-html-comment.md", (doc)=> {
        unowned GLib.Node<Elem> node0 = doc.root.nth_child(0);
        assert_nonnull(node0);
        if(node0 == null) {
            return; // can't test anything else
        }
        assert_true(node0.n_children() == 0);
    }, false);
}

// NOTE: if md4c-reader ever learns how to process HTML, change this test.
void test_html_comment_and_text()
{
    diag(GLib.Log.METHOD);
    read_and_test("200-html-comment-and-text.md", (doc)=> {
        unowned GLib.Node<Elem> node0 = doc.root.nth_child(0);
        assert_nonnull(node0);
        if(node0 == null) {
            return; // can't test anything else
        }
        assert_true(node0.n_children() == 0);
    }, false);
}
public static int main (string[] args)
{
    // run the tests
    My.App.init_before_run();
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
    Test.add_func("/200-md4c-reader/special_with_formatting", test_special_with_formatting);
    Test.add_func("/200-md4c-reader/italics", test_italics);
    Test.add_func("/200-md4c-reader/bold", test_bold);
    Test.add_func("/200-md4c-reader/inline_code", test_inline_code);
    Test.add_func("/200-md4c-reader/strike", test_strike);
    Test.add_func("/200-md4c-reader/underline", test_underline);
    Test.add_func("/200-md4c-reader/image", test_image);
    Test.add_func("/200-md4c-reader/html_comment", test_html_comment);
    Test.add_func("/200-md4c-reader/html_comment_and_text", test_html_comment_and_text);

    return Test.run();
}
