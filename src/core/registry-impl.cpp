// core/registry-impl.cpp
//
// Registry of classes.  See registry.vapi for documentation.
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include <stdio.h>
#include "registry.h"

GHashTable *my_get_registry()
{
    // Singleton hashtable
    static GHashTable *registry = g_hash_table_new(NULL, NULL);
    return registry;
}

void my_register_type(const gchar *name, GType ty,
                      const gchar *filename, const guint lineno)
{
    GHashTable *registry = my_get_registry();
    g_hash_table_insert(registry, (gpointer)name, (gpointer)ty);
    // DEBUG
    //printf("Registered %s, type %p, at %s:%u\n", name, (gpointer)ty,
    //        filename, lineno);
}
