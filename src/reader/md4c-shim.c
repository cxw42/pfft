// src/reader/md4c-shim.c: Vala interface shims for
// https://github.com/mity/md4c
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//
// See md4c.h license at end

#include "md4c-shim.h"

/** Create a renderer structure */
MD_PARSER *md4c_new_parser_()
{
    return (MD_PARSER*)calloc(1, sizeof(MD_PARSER));
}

/** Free a renderer structure */
void md4c_free_parser_(MD_PARSER *parser)
{
    free(parser);
}

gchar *md4c_get_info_string(void *code_detail)
{
    struct MD_BLOCK_CODE_DETAIL *detail = (struct MD_BLOCK_CODE_DETAIL *)code_detail;
    if(detail->info.text == NULL) {
        return g_strdup("");
    } else {
        return g_strndup((gchar *)detail->info.text, detail->info.size);
    }
}

void md4c_get_img_detail(void *code_detail, gchar **href, gchar **title)
{
    struct MD_SPAN_IMG_DETAIL *detail = (struct MD_SPAN_IMG_DETAIL *)code_detail;

    if(detail->src.text == NULL) {
        *href = g_strdup("");
    } else {
        *href = g_strndup((gchar *)detail->src.text, detail->src.size);
    }

    if(detail->title.text == NULL) {
        *title = g_strdup("");
    } else {
        *title = g_strndup((gchar *)detail->title.text, detail->title.size);
    }
}

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
