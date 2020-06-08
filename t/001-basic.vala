// 001-basic.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using Snapd;
/**
 * argv[0], for use by sanity()
 */
private string program_name;

void sanity()
{
    Test.message("%s: Running sanity test in %s() at %s:%d",
                 program_name, Log.METHOD, Log.FILE, Log.LINE);
    assert_true(true);
}

void loadfile()
{
    bool did_load = false;
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "001-basic.md");
        Test.message("Loading filename %s", fn);

        var md = new MarkdownSnapdReader();
        var doc = md.read_document(fn);
        did_load = true;
        Test.message("Got doc:\n%s\n", "# " + as_diag(doc.as_string()));
        assert_true(doc.content.length == 2);

        var node0 = doc.content.get(0);
        assert_true(node0.get_node_type() == MarkdownNodeType.PARAGRAPH);
        var kids0 = node0.get_children();
        assert_nonnull(kids0);
        if(kids0 != null) {
            assert_true(kids0.length == 1);
            var kid = kids0.get(0);
            assert_true(kid.get_node_type() == MarkdownNodeType.TEXT);
            assert_true(kid.get_text() == "# Header");
        }

        var node1 = doc.content.get(1);
        assert_true(node1.get_node_type() == MarkdownNodeType.PARAGRAPH);
        var kids1 = node1.get_children();
        assert_nonnull(kids1);
        if(kids1 != null) {
            assert_true(kids1.length == 1);
            var kid = kids1.get(0);
            assert_true(kid.get_node_type() == MarkdownNodeType.TEXT);
            assert_true(kid.get_text() == "Body");
        }
    } catch(FileError e) {
        warning("%s", e.message);
    }
    assert_true(did_load);
}

public static int main (string[] args)
{
    program_name = args[0];

//    // find the dir containing this executable
//    var me = File.new_for_commandline_arg(args[0]);
//    mydir = me.get_parent();

    // run the tests
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/001-basic/sanity", sanity);
    Test.add_func("/001-basic/loadfile", loadfile);

    return Test.run();
}
