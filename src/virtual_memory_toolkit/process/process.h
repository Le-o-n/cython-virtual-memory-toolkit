#ifndef PROCESS_H
#define PROCESS_H

#include <windows.h>
#include "virtual_memory_toolkit/handles/handle.h"
#include <TlHelp32.h>

typedef struct
{
    CAppHandle *app_handle;
    MODULEENTRY32 *loaded_modules;
    char *image_filename;
} CProcess;

#endif // PROCESS_H
