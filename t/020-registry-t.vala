// 020-registry.vala - tests of pfft plugin registration
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

class TestClass020 : Object
{
    /** Metadata for this class */
    [Description(blurb = "Sample")]
    public bool meta { get; default = false; }
}

void test_get_registry()
{
    assert_nonnull(get_registry());
}

void test_register()
{
    var registry = get_registry();
    assert_nonnull(registry);
    var ty = registry.get("testclass");
    assert_true(ty == typeof(TestClass020));
}

void just_for_coverage()
{
    var o = new TestClass020();
    assert_nonnull(o);
    assert_true(!o.meta);
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.set_nonfatal_assertions();

    register_type("testclass", typeof(TestClass020), GLib.Log.FILE, GLib.Log.LINE);

    Test.add_func("/020-registry/get_registry", test_get_registry);
    Test.add_func("/020-registry/register", test_register);
    Test.add_func("/020-registry/just_for_coverage", just_for_coverage);

    return Test.run();
}
