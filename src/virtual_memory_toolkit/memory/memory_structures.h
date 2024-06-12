#ifndef MEMORY_STRUCTURES_H
#define MEMORY_STRUCTURES_H

#include <windows.h>
#include "virtual_memory_toolkit/handles/handle.h"

typedef struct
{
    CAppHandle *app_handle;
    char *name;
    void *base_address;
    size_t size;
} CModule;

typedef struct
{
    CAppHandle *app_handle;
    void *address;
} CVirtualAddress;

#endif // MEMORY_STRUCTURES_H
