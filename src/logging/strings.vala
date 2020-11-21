// core/logging/strings.vala - string utilities
// Part of pfft, https://github.com/cxw42/pfft
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: LGPL-2.0-or-later

// substr() and related functions include code from vala's glib-2.0.vapi,
// licensed as follows:
/* glib-2.0.vala
 *
 * Copyright (C) 2006-2014  Jürg Billeter
 * Copyright (C) 2006-2008  Raffaele Sandrini
 * Copyright (C) 2007  Mathias Hasselmann
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * As a special exception, if you use inline functions from this file, this
 * file does not by itself cause the resulting executable to be covered by
 * the GNU Lesser General Public License.
 *
 * Author:
 *  Jürg Billeter <j@bitron.ch>
 *  Raffaele Sandrini <rasa@gmx.ch>
 *  Mathias Hasselmann <mathias.hasselmann@gmx.de>
 */

namespace My {
    /** A copy of memchr() from glib-2.0.vapi */
    [CCode (cname = "pfft_memchr", cheader_filename = "logging-c.h")]
    private extern char* pfft_memchr (char* s, int c, size_t n);

    // strnlen is not available on all systems
    /** A copy of strnlen() from glib-2.0.vapi */
    private static long pfft_strnlen (char* str, long maxlen) {
        char* end = pfft_memchr (str, 0, maxlen);
        if (end == null) {
            return maxlen;
        } else {
            return (long) (end - str);
        }
    }

    /** A copy of strndup() from glib-2.0.vapi */
    [CCode (cname = "pfft_strndup", cheader_filename = "logging-c.h")]
    private extern string pfft_strndup (char* str, size_t n);

    /**
     * A modified substring that doesn't log console messages.
     *
     * Per [[https://gitlab.gnome.org/GNOME/vala/-/issues/1105]], regular
     * {string.substring} logs to console for even ordinary behaviour.
     * This is a copy of string.substring but without that logging.
     *
     * @param str       The string
     * @param offset    As in {string.substring}
     * @param len       As in {string.substring}
     * @return As in {string.substring}
     */
    public string? substr (string str, long offset, long len = -1) {
        long string_length;
        if (offset >= 0 && len >= 0) {
            // avoid scanning whole string
            string_length = pfft_strnlen ((char*) str, offset + len);
        } else {
            string_length = str.length;
        }

        if (offset < 0) {
            offset = string_length + offset;
            if(offset < 0) return null;
        } else {
            if(offset > string_length) return null;
        }
        if (len < 0) {
            len = string_length - offset;
        }
        if(offset+len > string_length) return null;
        return pfft_strndup ((char*) str + offset, len);
    }
}
