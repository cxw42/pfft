// t/010-core-util.vala - tests of src/core/util.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

void test_diag()
{
    string s;

    s = diag_string("Hello, world!");
    assert_true(s == "# Hello, world!\n");
    s = diag_string("1\n2");
    assert_true(s == "# 1\n# 2\n");
    s = diag_string("1\n2\n");      // strips trailing whitespace
    assert_true(s == "# 1\n# 2\n");
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/010-core-util/diag", test_diag);

    return Test.run();
}
