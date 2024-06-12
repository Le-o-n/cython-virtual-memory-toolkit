

from libc.stdlib cimport malloc, free, calloc
from libc.string cimport memcpy, memcmp, strlen, strcpy
from libcpp.vector cimport vector
from errors import UnableToAcquireHandle

from VirtualMemoryToolkit.windows.windows_types cimport BYTE
from VirtualMemoryToolkit.windows.windows_types cimport PBYTE
from VirtualMemoryToolkit.windows.windows_types cimport QWORD   
from VirtualMemoryToolkit.windows.windows_types cimport DWORD         
from VirtualMemoryToolkit.windows.windows_types cimport WORD        
from VirtualMemoryToolkit.windows.windows_types cimport PDWORD       
from VirtualMemoryToolkit.windows.windows_types cimport HANDLE
from VirtualMemoryToolkit.windows.windows_types cimport HWND
from VirtualMemoryToolkit.windows.windows_types cimport HMODULE
from VirtualMemoryToolkit.windows.windows_types cimport ULONG_PTR
from VirtualMemoryToolkit.windows.windows_types cimport SIZE_T
from VirtualMemoryToolkit.windows.windows_types cimport LPSTR
from VirtualMemoryToolkit.windows.windows_types cimport LPCSTR
from VirtualMemoryToolkit.windows.windows_types cimport LPCVOID
from VirtualMemoryToolkit.windows.windows_types cimport LPVOID
from VirtualMemoryToolkit.windows.windows_types cimport PVOID
from VirtualMemoryToolkit.windows.windows_types cimport WCHAR
from VirtualMemoryToolkit.windows.windows_types cimport LPCWSTR
from VirtualMemoryToolkit.windows.windows_types cimport LPARAM
from VirtualMemoryToolkit.windows.windows_types cimport BOOL
from VirtualMemoryToolkit.windows.windows_types cimport WNDENUMPROC
from VirtualMemoryToolkit.windows.windows_types cimport MEMORY_BASIC_INFORMATION
from VirtualMemoryToolkit.windows.windows_types cimport PMEMORY_BASIC_INFORMATION
from VirtualMemoryToolkit.windows.windows_types cimport MODULEENTRY32
from VirtualMemoryToolkit.windows.windows_types cimport FIND_PROCESS_LPARAM

from VirtualMemoryToolkit.windows.windows_defs cimport GetWindowTextLengthA 
from VirtualMemoryToolkit.windows.windows_defs cimport GetWindowTextA 
from VirtualMemoryToolkit.windows.windows_defs cimport IsWindowVisible 
from VirtualMemoryToolkit.windows.windows_defs cimport GetWindowThreadProcessId 
from VirtualMemoryToolkit.windows.windows_defs cimport OpenProcess
from VirtualMemoryToolkit.windows.windows_defs cimport EnumWindows
from VirtualMemoryToolkit.windows.windows_defs cimport VirtualQueryEx
from VirtualMemoryToolkit.windows.windows_defs cimport VirtualProtectEx
from VirtualMemoryToolkit.windows.windows_defs cimport ReadProcessMemory
from VirtualMemoryToolkit.windows.windows_defs cimport WriteProcessMemory
from VirtualMemoryToolkit.windows.windows_defs cimport GetProcessImageFileNameA
from VirtualMemoryToolkit.windows.windows_defs cimport Module32First
from VirtualMemoryToolkit.windows.windows_defs cimport Module32Next
from VirtualMemoryToolkit.windows.windows_defs cimport CreateToolhelp32Snapshot
from VirtualMemoryToolkit.windows.windows_defs cimport GetLastError
from VirtualMemoryToolkit.windows.windows_defs cimport VirtualAllocEx
from VirtualMemoryToolkit.windows.windows_defs cimport VirtualFreeEx
from VirtualMemoryToolkit.windows.windows_defs cimport CloseHandle
from VirtualMemoryToolkit.windows.windows_defs cimport PrivilagedMemoryRead
from VirtualMemoryToolkit.windows.windows_defs cimport PrivilagedMemoryWrite
from VirtualMemoryToolkit.windows.windows_defs cimport PrivilagedSearchMemoryBytes
from VirtualMemoryToolkit.windows.windows_defs cimport CollectAllModuleInformation
from VirtualMemoryToolkit.windows.windows_defs cimport FindProcessFromWindowTitleSubstring

from VirtualMemoryToolkit.windows.windows_defs cimport MAX_PATH
from VirtualMemoryToolkit.windows.windows_defs cimport TH32CS_SNAPMODULE32
from VirtualMemoryToolkit.windows.windows_defs cimport TH32CS_SNAPMODULE
from VirtualMemoryToolkit.windows.windows_defs cimport MAX_MODULES
from VirtualMemoryToolkit.windows.windows_defs cimport PROCESS_ALL_ACCESS
from VirtualMemoryToolkit.windows.windows_defs cimport MEM_COMMIT
from VirtualMemoryToolkit.windows.windows_defs cimport PAGE_READWRITE
from VirtualMemoryToolkit.windows.windows_defs cimport PAGE_WRITECOPY
from VirtualMemoryToolkit.windows.windows_defs cimport PAGE_EXECUTE_READWRITE
from VirtualMemoryToolkit.windows.windows_defs cimport PAGE_EXECUTE_WRITECOPY
from VirtualMemoryToolkit.windows.windows_defs cimport PAGE_NOACCESS
from VirtualMemoryToolkit.windows.windows_defs cimport MEM_DECOMMIT


cdef extern from "VirtualMemoryToolkit/handles/handle.h":
    ctypedef struct CAppHandle:
        HANDLE process_handle
        HWND window_handle
        DWORD pid
        char* window_title

cdef inline CAppHandle* CAppHandle_init(void* process_handle, void* window_handle, unsigned int pid, char* window_title) nogil:
    """
    Creates a new CAppHandle instance with NULL fields.

    Parameters:
        process_handle (void*): handle to the process
        window_handle (void*): handle to the window
        pid (unsigned int): process id for the process
        window_title (char*): window title string
    Returns:
        CAppHandle*: A pointer to the newly created CAppHandle instance.
        Returns NULL if memory allocation fails.
    """
    cdef CAppHandle* app_handle = <CAppHandle*>malloc(sizeof(CAppHandle))
    if not app_handle:
        return NULL  # Memory allocation failed

    app_handle[0].process_handle = <HANDLE>process_handle
    app_handle[0].window_handle = <HWND>window_handle
    app_handle[0].pid = <DWORD>pid
    app_handle[0].window_title = window_title

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
        
    if app_handle[0].window_handle:
        CloseHandle(app_handle[0].window_handle)
    
    if app_handle[0].process_handle:
        CloseHandle(app_handle[0].process_handle)

    if app_handle[0].window_title:
        free(app_handle[0].window_title)
    free(app_handle)
