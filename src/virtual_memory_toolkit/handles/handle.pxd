

from libc.stdlib cimport malloc, free
from libc.string cimport strlen, strcpy


from virtual_memory_toolkit.windows.windows_types cimport DWORD         
from virtual_memory_toolkit.windows.windows_types cimport HANDLE
from virtual_memory_toolkit.windows.windows_types cimport HWND
from virtual_memory_toolkit.windows.windows_types cimport FIND_PROCESS_LPARAM

from virtual_memory_toolkit.windows.windows_defs cimport CloseHandle
from virtual_memory_toolkit.windows.windows_defs cimport FindProcessFromWindowTitleSubstring


cdef extern from "virtual_memory_toolkit/handles/handle.h":
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
