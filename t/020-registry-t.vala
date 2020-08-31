// 020-registry.vala - tests of pfft plugin registration
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

class TestClass : Object
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
    register_type("testclass", typeof(TestClass), GLib.Log.FILE, GLib.Log.LINE);
    assert_true(true);
    var registry = get_registry();
    assert_nonnull(registry);
    var ty = registry.get("testclass");
    assert_true(ty == typeof(TestClass));
}


public static int main (string[] args)
{
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/020-registry/get_registry", test_get_registry);
    Test.add_func("/020-registry/register", test_register);

    return Test.run();
}
