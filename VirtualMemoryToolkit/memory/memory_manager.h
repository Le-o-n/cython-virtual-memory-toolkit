#ifndef MEMORY_MANAGER_H
#define MEMORY_MANAGER_H

#include <windows.h>
#include "handle.h"

typedef struct{
    void* address;
    size_t size;
    CMemoryRegionNode* next;
    CMemoryRegionNode* prev;
}CMemoryRegionNode;


typedef struct{
    CAppHandle* app_handle;
    CMemoryRegionNode* memory_regions_head;
    CMemoryRegionNode* memory_regions_tail;

}CMemoryManager;

#endif // MEMORY_MANAGER_H
