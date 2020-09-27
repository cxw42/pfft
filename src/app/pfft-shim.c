// pfft-shim.c
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include <gst/gst.h>

/**
 * my_init_gstreamer:
 *
 * Initialize GStreamer.  This is to permit using earlier valac.  To initialize
 * GStreamer on Vala 0.47.1, you can do:
 * |[
 * string[] dummy_args = {""};
 * unowned var dargs = dummy_args;
 * Gst.init(ref dargs);
 * ]|
 * However, before 0.47.1, you can't use "unowned var", and you can't pass
 * null to Gst.init().  This function calls gst_init(null, null) so that you
 * can initialize GStreamer from any version of Vala.
 */
void my_init_gstreamer(void)
{
    gst_init(NULL, NULL);
}
