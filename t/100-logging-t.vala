// 100-logging.vala - tests of src/logging
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

void test_linit()   // for coverage
{
    My.Log.linit();
    assert_true(true);
}

void test_canonicalize()    // for coverage
{
    string t;
    t = My.Log.canonicalize_filename("/foo", null);
    assert_true(t == "/foo");
    t = My.Log.canonicalize_filename("foo", "/bar");
    assert_true(t == "/bar/foo");
    t = My.Log.canonicalize_filename("//foo", null);
    assert_true(t == "//foo");
    t = My.Log.canonicalize_filename("///foo", null);
    assert_true(t == "/foo");
    t = My.Log.canonicalize_filename("/foo/./bar", null);
    assert_true(t == "/foo/bar");
    t = My.Log.canonicalize_filename("/foo/bar/..", null);
    assert_true(t == "/foo");
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/100-logging/linit", test_linit);
    Test.add_func("/100-logging/canonicalize", test_canonicalize);

    return Test.run();
}
