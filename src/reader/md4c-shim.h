// src/reader/md4c-shim.h: Vala interface shims for
// https://github.com/mity/md4c
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//
// See md4c.h license at end

#ifndef MD4C_SHIM_H_
#define MD4C_SHIM_H_

#include <glib.h>
#include <stdlib.h>
#include "md4c.h"

/** Create a renderer structure */
MD_PARSER *md4c_new_parser_();

/** Free a renderer structure */
void md4c_free_parser_(MD_PARSER *parser);

/**
 * Duplicate the info string from an MD_BLOCK_CODE_DETAIL.
 * Returns: (transfer full): the info string
 *
 * This function exists because I was having trouble with member access
 * and didn't want to fuss with it.
 */
gchar *md4c_get_info_string(void *code_detail);

/**
 * Extract the strings from an MD_SPAN_IMG_DETAIL.
 * @img_detail: the input
 * @href: (out) (transfer full): The image URL
 * @title: (out) (transfer full): The title text
 *
 * This function exists because I was having trouble with member access
 * and didn't want to fuss with it.
 */
void md4c_get_img_detail(void *code_detail, gchar **href, gchar **title);

#endif /* MD4C_SHIM_H_ */
// md4c.h copyright notice follows
/*
 * MD4C: Markdown parser for C
 * (http://github.com/mity/md4c)
 *
 * Copyright (c) 2016-2020 Martin Mitas
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
