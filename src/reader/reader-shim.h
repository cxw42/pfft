// src/reader/reader-shim.h: Vala interface shims for readers
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#ifndef READER_SHIM_H_
#define READER_SHIM_H_

#include <glib.h>

/**
 * g_strndup with a non-const parameter
 */
gchar * g_strndup_shim(gchar *str, gsize n);

#endif /* READER_SHIM_H_ */
