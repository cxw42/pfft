// core/registry.h
//
// Definitions used in registering classes, and C++ defs behind registry.vapi.
// See registry.vapi for documentation and registry-impl.cpp for implementation.
//
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#ifndef PFFT_REGISTER_H_
#define PFFT_REGISTER_H_

#include <glib.h>
#include <glib-object.h>

// Usage: REGISTRAR_BEGIN(unique_id) { REGISTER();... } REGISTRAR_END
// or REGISTER_ONE(name, gtype)
#define REGISTRAR_BEGIN(unique_id) \
    REGISTRAR_BEGIN2(unique_id, __LINE__)

#define REG__NAME(uid, idx) \
    registry__function__ ## uid ## __ ##idx

#define REGISTRAR_BEGIN2(uid, idx) \
    void __attribute__((constructor)) REG__NAME(uid, idx) ()

#define REGISTER(name, gtype) \
        my_register_type((name), (gtype), __FILE__, __LINE__)

#define REGISTRAR_END

#define REGISTER_ONE(name, gtype) \
    REGISTRAR_BEGIN { \
        REGISTER((name), (gtype)) \
    } REGISTRAR_END

G_BEGIN_DECLS

extern GHashTable *my_get_registry();

extern void my_register_type(const gchar *name, GType ty,
        const gchar *filename, const guint lineno);

G_END_DECLS

#endif // PFFT_REGISTER_H_
