#!/usr/bin/env perl
# gen-myconfig.pl: generate myconfig.vapi from config.h.
# Part of pfft, https://github.com/cxw42/pfft
# Copyright (c) 2020 Christopher White.  All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

use 5.010001;
use strict;
use warnings;
use autodie;

exit main(@ARGV);

sub main {
    die "Usage: $0 CONFIG_H_FILENAME" unless @_ == 1;
    die "Invalid input filename" unless -r -f $_[0] && -s _;
    open my $fh, '<', $_[0];
    print <<EOT;
[CCode(cheader_filename = "config.h")]
namespace My {
EOT
    while(<$fh>) {
        next unless /^#\h*define\h+(\S+)/;
        print <<EOT;
        [CCode(cname = "$1")]
        public const string $1;
EOT
    }
    print <<EOT;
} //My
EOT
    return 0;
}
