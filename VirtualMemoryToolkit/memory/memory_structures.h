#ifndef MEMORY_STRUCTURES_H
#define MEMORY_STRUCTURES_H

#include <windows.h>
#include "handle.h"

typedef struct {
    char* name;
    void* base_address;
    size_t size;
} CModule;

typedef struct {
    CAppHandle *app_handle; 
    unsigned long long address;
} CVirtualAddress;

#endif // MEMORY_STRUCTURES_H
