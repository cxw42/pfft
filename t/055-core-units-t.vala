// t/055-core-units-t.vala - tests of unit parsing
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

void test_numbers()
{
    try {
        assert_true(1 == Units.parsedim("1"));
        assert_true(1 == Units.parsedim("1.0"));
        assert_true(1 == Units.parsedim("01.0"));
        assert_true(1 == Units.parsedim("1."));
        assert_true(-1 == Units.parsedim("-1."));
        assert_true(9 == Units.parsedim("9"));
        assert_true(9 == Units.parsedim("9.0"));
        assert_true(9 == Units.parsedim("09.0"));   // no octal floats! :)
        assert_true(1.5 == Units.parsedim("1.5"));  // assumes a binary machine
        assert_true(-1.5 == Units.parsedim("-1.5"));  // assumes a binary machine
        assert_true(-1.5 == Units.parsedim("-01.5"));
        assert_true(0.5 == Units.parsedim(".5"));
        assert_true(0.5 == Units.parsedim("0.5"));
        assert_true(-0.5 == Units.parsedim("-.5"));
        assert_true(-0.5 == Units.parsedim("-0.5"));
    } catch(My.Error e) {   // LCOV_EXCL_START - unreached if tests pass
        diag("Error: %s", e.message);
        assert_not_reached();
    }   // LCOV_EXCL_STOP
}

void test_inches()
{
    foreach(string unit in new string[] {" in", "in", "\tin"}) {
        try {
            assert_true(1 == Units.parsedim("1" + unit));
            assert_true(1 == Units.parsedim("1.0" + unit));
            assert_true(1 == Units.parsedim("01.0" + unit));
            assert_true(9 == Units.parsedim("9" + unit));
            assert_true(9 == Units.parsedim("9.0" + unit));
            assert_true(9 == Units.parsedim("09.0" + unit));
            assert_true(1.5 == Units.parsedim("1.5" + unit));
            assert_true(-1.5 == Units.parsedim("-1.5" + unit));
            assert_true(-1.5 == Units.parsedim("-01.5" + unit));
            assert_true(0.5 == Units.parsedim(".5" + unit));
            assert_true(0.5 == Units.parsedim("0.5" + unit));
            assert_true(-0.5 == Units.parsedim("-.5" + unit));
            assert_true(-0.5 == Units.parsedim("-0.5" + unit));
        } catch(My.Error e) {   // LCOV_EXCL_START - unreached if tests pass
            diag("Error: %s", e.message);
            assert_not_reached();
        }   // LCOV_EXCL_STOP
    }
}

void test_bad_numbers()
{
    foreach(var num in new string[] {".", "-.", "", "notanumber", "1a.3", "0x42",
                                     "pt", " pt", "Q", " Q"} // units are not numbers
    ) {
        try {
            Units.parsedim(num);
            assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass
        } catch(My.Error e) {
            assert_true(e is My.Error.INVALID_CONVERSION);
        }
    }
}

void test_bad_units()
{
    foreach(var unit in new string[] {".", "-.", "notaunit", "1a.3", "0x42"}) {
        try {
            Units.parsedim("1 " + unit);
            assert_not_reached();   // LCOV_EXCL_LINE - never happens if tests pass
        } catch(My.Error e) {
            assert_true(e is My.Error.INVALID_CONVERSION);
        }
    }
}

void test_units_unity()
{
    try {
        double dd = 72.27 /* tpt/in */ * 1157/1238 /* dd/tpt */;    // ~67.5/in.
        double cc = dd/12;  // ~5.6/in.

        assert_double_close(1.0/cc, Units.parsedim("1 cc"));
        assert_double_close(1.0/2.54, Units.parsedim("1 cm"));
        assert_double_close(1.0/dd, Units.parsedim("1 dd"));
        assert_double_close(12.0, Units.parsedim("1 ft"));
        assert_double_close(1.0, Units.parsedim("1 in"));
        assert_double_close(39.37, Units.parsedim("1 m"));
        assert_double_close(1.0/25.4, Units.parsedim("1 mm"));
        assert_double_close(1.0/6, Units.parsedim("1 pc"));
        assert_double_close(1.0/72, Units.parsedim("1 pt"));
        assert_double_close(1.0/96, Units.parsedim("1 px"));
        assert_double_close(1.0/(25.4*4), Units.parsedim("1 Q"));
        assert_double_close(1.0/(65536*72.27), Units.parsedim("1 sp"));
        assert_double_close(1.0/72.27, Units.parsedim("1 tpt"));
    } catch(My.Error e) {   // LCOV_EXCL_START - unreached if tests pass
        diag("Error: %s", e.message);
        assert_not_reached();
    }   // LCOV_EXCL_STOP
}

void test_quantity_and_unit()
{
    try {
        assert_double_close(1.0/72.27, Units.parsedim("65536 sp"));
    } catch(My.Error e) {   // LCOV_EXCL_START - unreached if tests pass
        diag("Error: %s", e.message);
        assert_not_reached();
    }   // LCOV_EXCL_STOP
}

public static int main (string[] args)
{
    App.init_before_run();
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/055-core-units/numbers", test_numbers);
    Test.add_func("/055-core-units/inches", test_inches);
    Test.add_func("/055-core-units/bad_numbers", test_bad_numbers);
    Test.add_func("/055-core-units/bad_units", test_bad_units);
    Test.add_func("/055-core-units/units_unity", test_units_unity);
    Test.add_func("/055-core-units/quantity_and_unit", test_quantity_and_unit);

    return Test.run();
}
