// t/070-core-writer-t.vala - tests of src/core/writer.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

private const string MSG = "Hello, world!\n";

void test_emit_file()
{
    try {
        string destfn, contents;
        FileUtils.close(FileUtils.open_tmp("pfft-t-XXXXXX", out destfn));
        Writer.emit(destfn, MSG);
        FileUtils.get_contents(destfn, out contents);
        assert_true(contents == MSG);

        try {
            var destf = File.new_for_path(destfn);
            destf.delete();
        } catch(GLib.Error e) {
            // ignore errors
        }

    } catch(FileError e) {  // LCOV_EXCL_START - unreached if tests pass
        diag("got file error: %s", e.message);
        assert_not_reached();
    }   // LCOV_EXCL_STOP
}

public static int main (string[] args)
{
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/070-core-writer/emit_file", test_emit_file);

    return Test.run();
}
