// t/021-registry-classmap.vala - part of pfft
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;
using My.Log;

class TestClass021 : Object
{
    /** Metadata for this class */
    [Description(blurb = "Sample")]
    public bool meta { get; default = false; }

    /** A property we can set */
    public string prop { get; set; default = ""; }

    /** Integer-valued property */
    public int number { get; set; default = -1; }

    /** Something you can get from a template */
    [Description(nick = "Font name", blurb = "Font of body text")]
    public string fontname { get; set; default = "Nonstandard"; }
}

private string K;

private ClassMap create_map()
{
    var m = new ClassMap();
    assert_nonnull(m);
    m.set(K, typeof(TestClass021));
    return m;
}

/** Check and cast a non-null TypeClass */
private TestClass021? tc_from_obj(Object? o)
{
    assert_nonnull(o);
    assert_true(o.get_type() == typeof(TestClass021));
    if(o == null) {
        return null; // LCOV_EXCL_LINE - unreached if tests pass
    }
    var tc = o as TestClass021;
    assert_nonnull(tc);
    if(tc == null) {
        return null; // LCOV_EXCL_LINE - unreached if tests pass
    }
    return tc;
}

void test_classmap_basic()
{
    var m = create_map();
    assert_true(m.has_key(K));
    assert_true(m.size == 1);
    assert_true(m.get(K) == typeof(TestClass021));
}

void test_create_instance()
{
    var m = create_map();
    Object instance;
    try {
        instance = m.create_instance(K, null, null);
    } catch(KeyFileError e) {   // LCOV_EXCL_START - unreached if tests pass
        warning("keyfile error: %s", e.message);
        assert_not_reached();
    } // LCOV_EXCL_STOP

    var tc = tc_from_obj(instance);
    if(tc == null) {
        return; // no other tests can succeed // LCOV_EXCL_LINE - unreached if tests pass
    }

    assert_true(tc.prop == "");
}

void test_create_instance_error()
{
    var m = create_map();
    Object instance;
    try {
        instance = m.create_instance("NONEXISTENT", null, null);
        assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass
    } catch(KeyFileError e) {
        diag("got error: %s\n", e.message);
        assert_true(e is KeyFileError.KEY_NOT_FOUND);
    }
}

void test_create_instance_with_options()
{
    string[] opts = { "prop=42" };
    var m = create_map();
    Object instance;
    try {
        instance = m.create_instance(K, null, opts);
    } catch(KeyFileError e) {   // LCOV_EXCL_START - unreached if tests pass
        warning("keyfile error: %s", e.message);
        assert_not_reached();
    } // LCOV_EXCL_STOP

    var tc = tc_from_obj(instance);
    if(tc == null) {
        return; // no other tests can succeed // LCOV_EXCL_LINE - unreached if tests pass
    }

    assert_true(tc.prop == "42");
}

void test_create_instance_with_invalid_options()
{
    var m = create_map();
    Object instance;

    string[] no_value = { "prop" };

    try {
        instance = m.create_instance(K, null, no_value);
        assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass
    } catch(KeyFileError e) {
        diag("no-value property: got error: %s\n", e.message);
        assert_true(e is KeyFileError.INVALID_VALUE);
    }

    string[] no_key = { "=42" };

    try {
        instance = m.create_instance(K, null, no_key);
        assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass
    } catch(KeyFileError e) {
        diag("no-key property: got error: %s\n", e.message);
        assert_true(e is KeyFileError.INVALID_VALUE);
    }

    string[] not_a_prop = { "NONEXISTENT=42" };

    try {
        instance = m.create_instance(K, null, not_a_prop);
        assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass
    } catch(KeyFileError e) {
        diag("not-a-prop: got error: %s\n", e.message);
        assert_true(e is KeyFileError.KEY_NOT_FOUND);
    }

    string[] not_a_number = { "number=oops" };

    try {
        instance = m.create_instance(K, null, not_a_number);
        assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass
    } catch(KeyFileError e) {
        diag("not-a-number: got error: %s\n", e.message);
        assert_true(e is KeyFileError.INVALID_VALUE);
    }
}

void test_set_props()
{
    var template = new Template();
    assert_nonnull(template);

    var m = create_map();
    Object instance;
    try {
        instance = m.create_instance(K, template, null);
    } catch(KeyFileError e) {   // LCOV_EXCL_START - unreached if tests pass
        warning("keyfile error: %s", e.message);
        assert_not_reached();
    } // LCOV_EXCL_STOP

    var tc = tc_from_obj(instance);
    if(tc == null) {
        return; // no other tests can succeed // LCOV_EXCL_LINE - unreached if tests pass
    }

    assert_true(tc.fontname == "Serif");    // default name from Template()
}

void test_just_for_coverage()
{
    var o = new TestClass021();
    assert_nonnull(o);
    assert_true(!o.meta);
    assert_true(o.number == -1);
}

public static int main (string[] args)
{
    K = "basic";
    App.init_before_run();
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/021-registry-classmap/classmap_basic", test_classmap_basic);
    Test.add_func("/021-registry-classmap/create_instance", test_create_instance);
    Test.add_func("/021-registry-classmap/create_instance_error", test_create_instance_error);
    Test.add_func("/021-registry-classmap/create_instance_with_options", test_create_instance_with_options);
    Test.add_func("/021-registry-classmap/create_instance_with_invalid_options", test_create_instance_with_invalid_options);
    Test.add_func("/021-registry-classmap/set_props", test_set_props);
    Test.add_func("/021-registry-classmap/just_for_coverage", test_just_for_coverage);

    return Test.run();
}
