// core/logging-c.h - Logging backend - definitions
// Part of pfft, https://github.com/cxw42/pfft
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: LGPL-2.1-or-later

// This file uses code from gstinfo.h, licensed as follows:
/* GStreamer
 * Copyright (C) 1999,2000 Erik Walthinsen <omega@cse.ogi.edu>
 *                    2000 Wim Taymans <wtay@chello.be>
 *                    2003 Benjamin Otte <in7y118@public.uni-hamburg.de>
 *
 * gstinfo.h: debugging functions
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

// and from glib/gfileutils.c, licensed as follows:
/* gfileutils.c - File utility functions
 *
 *  Copyright 2000 Red Hat, Inc.
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
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, see <http://www.gnu.org/licenses/>.
 */

// and from glib/gtestutils.h, licensed as follows:
/* GLib testing utilities
 * Copyright (C) 2007 Imendio AB
 * Authors: Tim Janik
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
 * License along with this library; if not, see <http://www.gnu.org/licenses/>.
 */

#ifndef LOGGING_C_H_
#define LOGGING_C_H_

#ifndef G_LOG_DOMAIN
#define G_LOG_DOMAIN "pfft"
#endif
#define GST_CAT_DEFAULT my_log_category

#include <float.h>
#include <gst/gst.h>

/**
 * my_log_category:
 *
 * Log category for messages from the pfft logging API
 */
GST_DEBUG_CATEGORY_EXTERN(my_log_category);

/**
 * my_log_lenabled:
 * @level: the severity of the message
 *
 * Conditional to determine whether logging is enabled for my_log_category
 * at the given @level.
 *
 * Modified from gst/gstinfo.h, macro GST_CAT_LEVEL_LOG(), as of
 * <https://gitlab.freedesktop.org/gstreamer/gstreamer/-/merge_requests/403>.
 * I am using the version from before
 * <https://gitlab.freedesktop.org/gstreamer/gstreamer/-/issues/564>
 * since this function is expressly meant to guard expensive debug statements.
 */
#define my_log_lenabled(level) ( \
  (G_UNLIKELY ((level) <= GST_LEVEL_MAX)) && ((level) <= _gst_debug_min) && \
  ((level) <= gst_debug_category_get_threshold (my_log_category)) \
  )

/**
 * my_log_linit:
 *
 * Initialize my_log_category.  Call gst_init() first.
 */
extern void my_log_linit();

/**
 * my_canonicalize_filename:
 *
 * A copy of g_canonicalize_filename, which was added to Glib after
 * Ubuntu Bionic (GLib 2.56).
 *
 * This doesn't belong in a logging library, but since this is the LGPL
 * part of pfft, here it is!
 */
gchar *
my_canonicalize_filename (const gchar *filename,
                         const gchar *relative_to);

/**
 * my_assert_cmpfloat:
 *
 * A copy of g_assert_cmpfloat, which was added to GLib after Bionic.
 */
#define my_assert_cmpfloat(n1,cmp,n2)    \
    G_STMT_START { \
        long double __n1 = (long double) (n1), __n2 = (long double) (n2); \
        if (__n1 cmp __n2) ; else \
            g_assertion_message_cmpnum (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, \
                #n1 " " #cmp " " #n2, (long double) __n1, #cmp, (long double) __n2, 'f'); \
    } G_STMT_END

/**
 * my_assert_cmpfloat_with_epsilon:
 *
 * A copy of g_assert_cmpfloat_with_epsilon, which was added to GLib after Bionic.
 */
#define my_assert_cmpfloat_with_epsilon(n1,n2,epsilon) \
    G_STMT_START { \
        double __n1 = (n1), __n2 = (n2), __epsilon = (epsilon); \
        if (G_APPROX_VALUE (__n1,  __n2, __epsilon)) ; else \
            g_assertion_message_cmpnum (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, \
                #n1 " == " #n2 " (+/- " #epsilon ")", __n1, "==", __n2, 'f'); \
    } G_STMT_END

/**
 * my_assert_double_close:
 *
 * g_assert_cmpfloat_with_epsilon(), but always using %DBL_EPSILON.
 */
#define my_assert_double_close(n1,n2) \
    my_assert_cmpfloat_with_epsilon((n1), (n2), DBL_EPSILON)

#endif /* LOGGING_C_H_ */
