// src/reader/register.cpp
//
// Register the known reader classes on startup
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include "registry.h"
#include "pfft-reader.h"

REGISTRAR_BEGIN(readers) {
    REGISTER("mdsimple", MY_TYPE_MARKDOWN_SNAPD_READER);
    REGISTER("markdown", MY_TYPE_MARKDOWN_MD4C_READER);
} REGISTRAR_END
