// 001-sanity-t.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;
/**
 * argv[0], for use by sanity()
 */
private string program_name;

void test_sanity()
{
    Test.message("%s: Running sanity test in %s() at %s:%d",
        program_name, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
    assert_true(true);
}

public static int main (string[] args)
{
    program_name = args[0];

    // run the tests
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/001-sanity/sanity", test_sanity);

    return Test.run();
}
