// 001-basic.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

private string program_name;

public void sanity()
{
    Test.message("%s: Running sanity test in %s() at %s:%d",
                 program_name, Log.METHOD, Log.FILE, Log.LINE);
    assert_true(true);
}

public void loadfile()
{
    bool ok = false;
    try {
        var md = new MarkdownSnapdReader();
        var fn = Test.build_filename(Test.FileType.DIST, "001-basic.md");
        Test.message("Loading filename %s", fn);
        var doc = md.read_document(fn);
        Test.message("Got %d nodes", doc.content.length);
        assert_true(doc.content.length == 2);
        ok = true;
    } catch(FileError e) {
        warning("%s", e.message);
    }
    assert_true(ok);
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
