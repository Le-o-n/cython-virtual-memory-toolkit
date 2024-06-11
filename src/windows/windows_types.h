#ifndef WINDOWS_TYPES_H
#define WINDOWS_TYPES_H

#include <windows.h>

typedef struct FIND_PROCESS_LPARAM
{
    const char *in_window_name_substring; // Input: Part of the window name to search for
    HWND out_window_handle;               // Output: Handle to the found window
    DWORD out_pid;                        // Output: Process ID of the found process
    HANDLE out_all_access_process_handle; // Output: Handle to the process with all access rights
    char *out_full_window_name;           // Output: Full name of the found window
} FIND_PROCESS_LPARAM;

#endif // WINDOWS_TYPES_H