// src/reader/reader-shim.c: Vala interface shims for readers
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include "reader-shim.h"

/**
 * g_strndup with a non-const parameter
 */
gchar * g_strndup_shim(gchar *str, gsize n)
{
    return g_strndup((const gchar *)str, n);
}
