#ifndef MEMORY_MANAGER_H
#define MEMORY_MANAGER_H

#include <windows.h>
#include "virtual_memory_toolkit/handles/handle.h"

typedef struct CMemoryRegionNode
{
    void *address;
    size_t size;
    struct CMemoryRegionNode *next;
    struct CMemoryRegionNode *prev;
} CMemoryRegionNode;

typedef struct
{
    CAppHandle *app_handle;
    CMemoryRegionNode *memory_regions_head;
    CMemoryRegionNode *memory_regions_tail;

} CMemoryManager;

#endif // MEMORY_MANAGER_H
