// t/300-pango-markup-writer-t.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

Doc create_dummy_doc()
{
    GLib.Node<Elem> root = node_of_ty(Elem.Type.ROOT);
    GLib.Node<Elem> node;
    unowned GLib.Node<Elem> unode;

    node = node_of_ty(BLOCK_COPY);
    unode = node;
    root.append((owned)node);

    node = node_of_ty(SPAN_PLAIN);
    node.data.text = "Hello, world!";
    unode.append((owned)node);

    var retval = new Doc((owned)root);
    assert_true(root == null);
    assert_nonnull(retval);
    return retval;
}

void test_writefile()
{
    bool did_write = false;
    File destf = null;
    string destfn;

    try {
        FileUtils.close(FileUtils.open_tmp("pfft-t-XXXXXX", out destfn));
        var doc = create_dummy_doc();

        // Write it
        var writer = new PangoMarkupWriter();
        writer.write_document(destfn, doc);

        // Check it
        destf = File.new_for_path(destfn);
        uint8[] contents;
        string etag_out;

        destf.load_contents (null, out contents, out etag_out);
        did_write = destf.query_exists() && (contents.length > 0);
            // TODO make this check more sophisticated

    } catch(FileError e) {
        warning("file error: %s", e.message);
        assert_not_reached();
    } catch(My.Error e) {
        warning("pfft error: %s", e.message);
        assert_not_reached();
    } catch(GLib.Error e) {
        warning("glib error: %s", e.message);
        assert_not_reached();
    }
    assert_true(did_write);

    // Clean up
    try {
        if(destf != null) {
            destf.delete();
        }
    } catch(GLib.Error e) {
        //ignore errors
    }

} //test_writefile()

/** Test bad inputs to write_document */
void test_badcall()
{
    File destf = null;
    string destfn;

    // Create a temporary file.  The ok+assert_not_reached() dance is to
    // avoid unhandled-exception and unreachable-code warnings.
    bool ok = true;
    try {
        FileUtils.close(FileUtils.open_tmp("pfft-t-XXXXXX", out destfn));
    } catch {
        ok = false;
        assert_not_reached();
    }
    if(!ok) {
        return;
    }

    destf = File.new_for_path(destfn);

    var writer = new PangoMarkupWriter();

    // No filename
    try {
        var doc = create_dummy_doc();
        writer.write_document("", doc); // Should throw
        assert_not_reached();
    } catch(My.Error e) {
        printerr("got error: %s\n", e.message);
        assert_true(e is My.Error.WRITER);
    } catch(FileError e) {
        warning("file error: %s", e.message);
        assert_not_reached();
    }

    // Document with no nodes
    try {
        var node = node_of_ty(SPAN_PLAIN);
        var doc = new Doc((owned)node);
        doc.root = null;
        writer.write_document(destfn, doc);
        assert_not_reached();
    } catch(My.Error e) {
        printerr("got error: %s\n", e.message);
        assert_true(e is My.Error.WRITER);
    } catch(FileError e) {
        warning("file error: %s", e.message);
        assert_not_reached();
    }

    // Document without a root node
    try {
        var node = node_of_ty(SPAN_PLAIN);
        var doc = new Doc((owned)node);
        writer.write_document(destfn, doc);
        assert_not_reached();
    } catch(My.Error e) {
        printerr("got error: %s\n", e.message);
        assert_true(e is My.Error.WRITER);
    } catch(FileError e) {
        warning("file error: %s", e.message);
        assert_not_reached();
    }

    // Clean up
    try {
        if(destf != null) {
            destf.delete();
        }
    } catch(GLib.Error e) {
        //ignore errors
    }

}

public static int main (string[] args)
{
    // run the tests
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/300-pango-markup-writer/writefile", test_writefile);
    Test.add_func("/300-pango-markup-writer/badcall", test_badcall);

    return Test.run();
}
