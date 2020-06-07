// 001-basic.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

public void sanity()
{
    assert_true(true);
}

public void loadfile()
{
    bool ok = false;
    try {
        var md = new MarkdownSnapdReader();
        var doc = md.read_document("001-basic.md");
        ok = true;
    } catch(FileError e) {
        warning("%s", e.message);
    }
    assert_true(ok);
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.add_func("/001-basic/sanity", sanity);
    Test.add_func("/001-basic/loadfile", loadfile);
    return Test.run();
}
