// t/305-pango-markup-utils-t.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

void test_U()
{
    assert_true(U(65) == "A");
    assert_true(U(0x115) == "ĕ");
}

void test_unit_conversions()
{
    assert_true(1 == p2i(72*Pango.SCALE));
    assert_true(72*Pango.SCALE == i2p(1));
    assert_double_close(72, i2c(1));
    assert_double_close(1, c2i(72));
}

public static int main (string[] args)
{
    // run the tests
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/305-pango-markup-utils/U", test_U);
    Test.add_func("/305-pango-markup-utils/unit_conversions", test_unit_conversions);

    return Test.run();
}

// vi: set fenc=utf8: //
