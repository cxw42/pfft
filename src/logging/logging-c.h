// core/logging-c.h - Logging backend - definitions
// Part of pfft, https://github.com/cxw42/pfft
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: LGPL-2.0-or-later

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


#ifndef LOGGING_C_H_
#define LOGGING_C_H_

#define GST_CAT_DEFAULT my_log_category
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

#endif /* LOGGING_C_H_ */
