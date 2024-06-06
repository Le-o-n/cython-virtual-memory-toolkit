

from libc.stdlib cimport malloc, free, calloc
from libc.string cimport memcpy, memcmp, strlen, strcpy
from libcpp.vector cimport vector
from errors import UnableToAcquireHandle

from windows.windows_types cimport BYTE
from windows.windows_types cimport PBYTE
from windows.windows_types cimport QWORD   
from windows.windows_types cimport DWORD         
from windows.windows_types cimport WORD        
from windows.windows_types cimport PDWORD       
from windows.windows_types cimport HANDLE
from windows.windows_types cimport HWND
from windows.windows_types cimport HMODULE
from windows.windows_types cimport ULONG_PTR
from windows.windows_types cimport SIZE_T
from windows.windows_types cimport LPSTR
from windows.windows_types cimport LPCSTR
from windows.windows_types cimport LPCVOID
from windows.windows_types cimport LPVOID
from windows.windows_types cimport PVOID
from windows.windows_types cimport WCHAR
from windows.windows_types cimport LPCWSTR
from windows.windows_types cimport LPARAM
from windows.windows_types cimport BOOL
from windows.windows_types cimport WNDENUMPROC
from windows.windows_types cimport MEMORY_BASIC_INFORMATION
from windows.windows_types cimport PMEMORY_BASIC_INFORMATION
from windows.windows_types cimport MODULEENTRY32
from windows.windows_types cimport FIND_PROCESS_LPARAM

from windows.windows_defs cimport GetWindowTextLengthA 
from windows.windows_defs cimport GetWindowTextA 
from windows.windows_defs cimport IsWindowVisible 
from windows.windows_defs cimport GetWindowThreadProcessId 
from windows.windows_defs cimport OpenProcess
from windows.windows_defs cimport EnumWindows
from windows.windows_defs cimport VirtualQueryEx
from windows.windows_defs cimport VirtualProtectEx
from windows.windows_defs cimport ReadProcessMemory
from windows.windows_defs cimport WriteProcessMemory
from windows.windows_defs cimport GetProcessImageFileNameA
from windows.windows_defs cimport Module32First
from windows.windows_defs cimport Module32Next
from windows.windows_defs cimport CreateToolhelp32Snapshot
from windows.windows_defs cimport GetLastError
from windows.windows_defs cimport VirtualAllocEx
from windows.windows_defs cimport VirtualFreeEx
from windows.windows_defs cimport CloseHandle
from windows.windows_defs cimport PrivilagedMemoryRead
from windows.windows_defs cimport PrivilagedMemoryWrite
from windows.windows_defs cimport PrivilagedSearchMemoryBytes
from windows.windows_defs cimport CollectAllModuleInformation
from windows.windows_defs cimport FindProcessFromWindowTitleSubstring

from windows.windows_defs cimport MAX_PATH
from windows.windows_defs cimport TH32CS_SNAPMODULE32
from windows.windows_defs cimport TH32CS_SNAPMODULE
from windows.windows_defs cimport MAX_MODULES
from windows.windows_defs cimport PROCESS_ALL_ACCESS
from windows.windows_defs cimport MEM_COMMIT
from windows.windows_defs cimport PAGE_READWRITE
from windows.windows_defs cimport PAGE_WRITECOPY
from windows.windows_defs cimport PAGE_EXECUTE_READWRITE
from windows.windows_defs cimport PAGE_EXECUTE_WRITECOPY
from windows.windows_defs cimport PAGE_NOACCESS
from windows.windows_defs cimport MEM_DECOMMIT


cdef extern from "handle.h":
    ctypedef struct CAppHandle:
        HANDLE process_handle
        HWND window_handle
        DWORD pid
        char* window_title

cdef inline CAppHandle* CAppHandle_new() nogil:
    """
    Creates a new CAppHandle instance with NULL fields.

    Returns:
        CAppHandle*: A pointer to the newly created CAppHandle instance.
        Returns NULL if memory allocation fails.
    """
    cdef CAppHandle* app_handle = <CAppHandle*>malloc(sizeof(CAppHandle))
    if not app_handle:
        return NULL  # Memory allocation failed

    app_handle[0].process_handle = NULL
    app_handle[0].window_handle = NULL
    app_handle[0].pid = 0
    app_handle[0].window_title = NULL

    return app_handle



cdef inline CAppHandle* CAppHandle_from_title_substring(const char* title_sub_string) nogil:
    """
    Creates a new CAppHandle instance and populates its fields from a window title substring.

    Parameters:
        title_sub_string (char*): Substring of the window title to search for.

    Returns:
        CAppHandle*: A pointer to the newly created CAppHandle instance.
        Returns NULL if any operation fails.
    """
    cdef CAppHandle* app_handle = <CAppHandle*>malloc(sizeof(CAppHandle))
    if not app_handle:
        return NULL  # Memory allocation failed

    cdef FIND_PROCESS_LPARAM window_data = FindProcessFromWindowTitleSubstring(title_sub_string)
    if not window_data.out_window_handle or not window_data.out_all_access_process_handle:
        free(app_handle)
        return NULL  # Failed to find process from window title substring

    app_handle[0].window_handle = window_data.out_window_handle
    app_handle[0].process_handle = window_data.out_all_access_process_handle
    app_handle[0].pid = window_data.out_pid

    app_handle[0].window_title = <char*>malloc((strlen(window_data.out_full_window_name) + 1) * sizeof(char))
    if not app_handle[0].window_title:
        free(app_handle)
        return NULL  # Memory allocation failed

    strcpy(app_handle[0].window_title, window_data.out_full_window_name)

    return app_handle



cdef inline void CAppHandle_free(CAppHandle* app_handle) nogil:
    """
    Frees the memory allocated for a CAppHandle instance.

    Parameters:
        app_handle (CAppHandle*): The CAppHandle instance to be freed.
    """
    if not app_handle:
        return

    if app_handle[0].window_title:
        free(app_handle[0].window_title)
    free(app_handle)
