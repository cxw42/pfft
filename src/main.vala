// main.vala - part of pfft
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

/** main() */
public static int main(string[] args)
{
    My.App.init_before_run();
    var app = new My.App();
    var arg_copy = strdupv(args);
    var status = app.run((owned)arg_copy);
    if(status != 0) {
        printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
    }
    return status;
}
