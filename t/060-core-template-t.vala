// 060-core-template-t.vala - tests of src/core/template.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

// Test loading a valid file with plaintext headers and footers
void test_load_file()
{
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "060-core-template.pfft");
        var template = new Template.from_file(fn);
        assert_true(template != null);
        if(template == null) {
            return;
        }

        assert_true(template.data.has_group("pfft"));
        assert_true(template.data.has_group("page"));
        assert_true(template.data.has_group("margin"));

        var ver = template.data.get_integer("pfft", "version");
        assert_true(ver==1);

        // Note: direct float comparisons
        assert_true(template.paperheightI == 21);
        assert_true(template.paperwidthI == 22);
        assert_true(template.lmarginI == 3);
        assert_true(template.tmarginI == 4);
        assert_true(template.vsizeI == (21-4-6));
        assert_true(template.hsizeI == (22-3-5));
        assert_true(template.headerskipI == 7);
        assert_true(template.footerskipI == 8);

        assert_true(template.headerl == "Hl&lt;");
        assert_true(template.headerc == "Hc&lt;");
        assert_true(template.headerr == "Hr&lt;");
        assert_true(template.footerl == "Fl&lt;");
        assert_true(template.footerc == "Fc&lt;");
        assert_true(template.footerr == "Fr&lt;");

        assert_true(template.fontsizeT == 1337);

    } catch(KeyFileError e) {
        warning("keyfile error: %s", e.message);
        assert_not_reached();
    } catch(FileError e) {
        warning("file error: %s", e.message);
        assert_not_reached();
    }
}

// Test header and footer markup
void test_headfoot_markup()
{
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "060-headfoot-markup.pfft");
        var template = new Template.from_file(fn);
        assert_true(template != null);
        if(template == null) {
            return;
        }

        assert_true(template.data.has_group("pfft"));

        var ver = template.data.get_integer("pfft", "version");
        assert_true(ver==1);

        // Raw markup, so the '<' doesn't get escaped
        assert_true(template.headerl == "Hl<");
        assert_true(template.headerc == "Hc<");
        assert_true(template.headerr == "Hr<");
        assert_true(template.footerl == "Fl<");
        assert_true(template.footerc == "Fc<");
        assert_true(template.footerr == "Fr<");

    } catch(KeyFileError e) {
        warning("keyfile error: %s", e.message);
        assert_not_reached();
    } catch(FileError e) {
        warning("file error: %s", e.message);
        assert_not_reached();
    }
}

// Test header.left and header.leftmarkup in one file.  I am using this as a
// proxy for the remaining five of {header,footer}.{left,center,right}*.
void test_both_headleft()
{
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "060-both-headleft.pfft");
        var template = new Template.from_file(fn);
        template = null;   // suppress "unused" warning
        assert_not_reached();
    } catch(KeyFileError e) {
        diag("got keyfile error: %s", e.message);
        assert_true(e is KeyFileError.PARSE);
    } catch(FileError e) {
        diag("got file error: %s", e.message);
        assert_not_reached();
    }
}
void test_bad_filename()
{
    File destf = null;

    try {
        // make a filename that doesn't exist
        string destfn;
        FileUtils.close(FileUtils.open_tmp("pfft-t-XXXXXX", out destfn));
        destf = File.new_for_path(destfn);
        try {
            destf.delete();
        } catch(GLib.Error e) {
            // ignore errors
        }

        var t = new Template.from_file(destfn);
        t = null;   // suppress "unused" warning
        assert_not_reached();
    } catch(FileError e) {
        diag("got file error: %s", e.message);
        assert_true(e is FileError.FAILED || e is FileError.NOENT);
    } catch {
        warning("Unhandled error");
        assert_not_reached();
    }
}

// Test an invalid file
void test_bad_file()
{
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "060-no-magic.pfft");
        var template = new Template.from_file(fn);
        template = null;   // suppress "unused" warning
        assert_not_reached();
    } catch(KeyFileError e) {
        diag("got keyfile error: %s", e.message);
        assert_true(e is KeyFileError.GROUP_NOT_FOUND);
    } catch(FileError e) {
        diag("got file error: %s", e.message);
        assert_not_reached();
    }
}

// Test a file of a version we don't recognize
void test_bad_version()
{
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "060-bad-version.pfft");
        var template = new Template.from_file(fn);
        template = null;   // suppress "unused" warning
        assert_not_reached();
    } catch(KeyFileError e) {
        diag("got keyfile error: %s", e.message);
        assert_true(e is KeyFileError.PARSE);
    } catch(FileError e) {
        diag("got file error: %s", e.message);
        assert_not_reached();
    }
}

// Test a valid but content-free file.  Also test the default constructor,
// for coverage.
void test_empty_file()
{
    string[] tef_filenames = {
        Test.build_filename(Test.FileType.DIST, "060-empty.pfft"),
        Test.build_filename(Test.FileType.DIST, "060-empty-groups.pfft")
    };

    for(int which = 0; which < 1 + tef_filenames.length; ++which) {
        try {
            Template template;
            if(which == 0) {
                diag("Testing default ctor");
                template = new Template();

            } else {
                var fn = tef_filenames[which-1];
                diag(@"Loading from $fn");
                template = new Template.from_file(fn);
            }

            assert_true(template != null);
            if(template == null) {
                continue;
            }

            // Check the default values.
            // Caution: direct float comparisons
            assert_true(template.paperheightI == 11);
            assert_true(template.paperwidthI == 8.5);
            assert_true(template.lmarginI == 1);
            assert_true(template.tmarginI == 1);
            assert_true(template.vsizeI == 9);
            assert_true(template.hsizeI == 6.5);
            assert_true(template.headerskipI == 0.4);
            assert_true(template.footerskipI == 0.3);

            assert_true(template.headerl == "");
            assert_true(template.headerc == "");
            assert_true(template.headerr == "");
            assert_true(template.footerl == "");
            assert_true(template.footerc == "%p");
            assert_true(template.footerr == "");

            assert_true(template.fontsizeT == 12);

        } catch(KeyFileError e) {
            diag("got keyfile error: %s", e.message);
            assert_not_reached();
        } catch(FileError e) {
            diag("got file error: %s", e.message);
            assert_not_reached();
        }
    } // for(which)
}

// Test invalid values in a valid file
void test_invalid_values()
{
    try {
        var fn = Test.build_filename(Test.FileType.DIST, "060-bad-values.pfft");
        var template = new Template.from_file(fn);
        assert_true(template != null);
        if(template == null) {
            return;
        }

        assert_true(template.paperheightI == 11);
    } catch(KeyFileError e) {
        diag("got keyfile error: %s", e.message);
        assert_not_reached();
    } catch(FileError e) {
        diag("got file error: %s", e.message);
        assert_not_reached();
    }
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/060-core-template/load_file", test_load_file);
    Test.add_func("/060-core-template/headfoot_markup", test_headfoot_markup);
    Test.add_func("/060-core-template/both_headleft", test_both_headleft);
    Test.add_func("/060-core-template/bad_filename", test_bad_filename);
    Test.add_func("/060-core-template/bad_file", test_bad_file);
    Test.add_func("/060-core-template/bad_version", test_bad_version);
    Test.add_func("/060-core-template/empty_file", test_empty_file);
    Test.add_func("/060-core-template/invalid_values", test_invalid_values);

    return Test.run();
}
