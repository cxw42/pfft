// src/writer/register.cpp
//
// Register the known writer classes on startup
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include "registry.h"
#include "pfft-writer.h"

REGISTRAR_BEGIN(writers) {
    REGISTER("pdf", MY_TYPE_PANGO_MARKUP_WRITER);
    REGISTER("dumper", MY_TYPE_TREE_DUMPER_WRITER);
} REGISTRAR_END
