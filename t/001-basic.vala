// 001-basic.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

public void testcase()
{
    assert_true(true);
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.add_func("/001-basic/sanity", testcase);
    Test.run();
    return 0;
}
