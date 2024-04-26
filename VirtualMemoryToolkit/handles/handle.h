#ifndef HANDLE_H
#define HANDLE_H

#include <windows.h>

typedef struct CAppHandle {
    HANDLE process_handle;
    HWND window_handle;
    DWORD pid;
    char* window_title;
} CAppHandle;

#endif // HANDLE_H