// 050-core-el.vala - tests of src/core/el.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

private Elem new_elem()
{
    var el = new Elem(BLOCK_HEADER);
    el.text = "t";
    el.header_level = 1;
    el.info_string = "i";
    el.href = "h";

    return el;
}

void test_clone()
{
    var el = new_elem();
    var el2 = el.clone();
    assert_true(el2.text == el.text);
    assert_true(el2.header_level == el.header_level);
    assert_true(el2.info_string  == el.info_string);
    assert_true(el2.href == el.href);
}

void test_as_string()
{
    var el = new_elem();
    assert_true(el.as_string() == "MY_ELEM_TYPE_BLOCK_HEADER/i: -t-");
    el.info_string = "";
    assert_true(el.as_string() == "MY_ELEM_TYPE_BLOCK_HEADER: -t-");
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/050-core-el/clone", test_clone);
    Test.add_func("/050-core-el/as_string", test_as_string);

    return Test.run();
}
