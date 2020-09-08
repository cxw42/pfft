// t/200-md4c-reader-t.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

void test_loadfile()
{
    bool did_load = false;
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "basic.md");
        Test.message("Loading filename %s", fn);

        var md = new MarkdownMd4cReader();
        Doc doc = md.read_document(fn);
        assert_nonnull(doc);
        did_load = true;
        Test.message("Got doc:\n%s\n", as_diag(doc.as_string()));
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
    } catch(FileError e) {
        warning("file error: %s", e.message);
        assert_not_reached();
    } catch(GLib.MarkupError e) {
        warning("%s", e.message);
        assert_not_reached();
    }
    assert_true(did_load);
}

public static int main (string[] args)
{
    // run the tests
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/200-md4c-reader/loadfile", test_loadfile);

    return Test.run();
}
