// t/071-core-writer-emit-t.vala - tests of My.Writer.emit()
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

using My;

void test_emit_stdout()
{
    try {
        Writer.emit("-","# emitted message\n");
        assert_true(true);
    } catch(FileError e) {  // LCOV_EXCL_START - unreached if tests pass
        diag("got file error: %s", e.message);
        assert_not_reached();
    }   // LCOV_EXCL_STOP
}

public static int main (string[] args)
{
    // Special case: emit to stdout so t/071-core-writer-emit.sh can check it
    if(args.length == 2 && args[1] == "emit") {

        try {
            Writer.emit("-","magicmessage\n");
            return 0;
        } catch(FileError e) {  // LCOV_EXCL_START - unreached if tests pass
            diag("got file error: %s", e.message);
            return 1;
        }   // LCOV_EXCL_STOP
    }

    // Normal case: just check that the emit succeeded.
    Test.init (ref args);
    Test.set_nonfatal_assertions();
    Test.add_func("/071-core-writer-emit/emit_stdout", test_emit_stdout);

    return Test.run();
}
