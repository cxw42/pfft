// core/logging-c.c - Logging backend.
// Part of pfft, https://github.com/cxw42/pfft
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "logging-c.h"

GST_DEBUG_CATEGORY(my_log_category);

void my_log_linit()
{
    GST_DEBUG_CATEGORY_INIT(my_log_category, "pfft", 0, "");
}
