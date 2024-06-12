from libc.stdlib cimport malloc, free

from virtual_memory_toolkit.handles.handle cimport CAppHandle

from virtual_memory_toolkit.windows.windows_types cimport MODULEENTRY32
from virtual_memory_toolkit.windows.windows_types cimport HANDLE, DWORD

from virtual_memory_toolkit.windows.windows_defs cimport GetProcessImageFileNameA
from virtual_memory_toolkit.windows.windows_defs cimport CollectAllModuleInformation
from virtual_memory_toolkit.windows.windows_defs cimport CreateToolhelp32Snapshot

from virtual_memory_toolkit.windows.windows_defs cimport TH32CS_SNAPMODULE
from virtual_memory_toolkit.windows.windows_defs cimport TH32CS_SNAPMODULE32
from virtual_memory_toolkit.windows.windows_defs cimport MAX_PATH, INVALID_HANDLE_VALUE

cdef extern from "virtual_memory_toolkit/process/process.h":
    ctypedef struct CProcess:
        CAppHandle* app_handle
        MODULEENTRY32* loaded_modules
        char* image_filename
    

cdef inline CProcess* CProcess_init(CAppHandle* app_handle) nogil:
    """
    Creates a new CProcess instance and populates its fields.

    Parameters:
        app_handle (CAppHandle*): The application handle.

    Returns:
        CProcess*: A pointer to the newly created CProcess instance.
        Returns NULL if memory allocation or other operations fail.
    """
    cdef CProcess* process = <CProcess*>malloc(sizeof(CProcess))
    if not process:
        return NULL  # Memory allocation failed

    cdef HANDLE snapshot32 = CreateToolhelp32Snapshot(
        TH32CS_SNAPMODULE32 | TH32CS_SNAPMODULE,
        app_handle[0].pid
    )

    if snapshot32 == INVALID_HANDLE_VALUE:
        free(process)
        return NULL  # Unable to get snapshot of process

    process[0].app_handle = app_handle
    process[0].loaded_modules = CollectAllModuleInformation(snapshot32)
    if not process[0].loaded_modules:
        free(process)
        return NULL  # Failed to collect module information

    process[0].image_filename = <char*>malloc(sizeof(char) * MAX_PATH)
    if not process[0].image_filename:
        free(process[0].loaded_modules)
        free(process)
        return NULL  # Memory allocation failed
    
    if not GetProcessImageFileNameA(
        app_handle[0].process_handle, 
        process[0].image_filename,
        MAX_PATH
    ):
        free(process[0].image_filename)
        free(process[0].loaded_modules)
        free(process)
        return NULL  # Unable to get process file name

    return process


cdef inline void CProcess_free(CProcess* process) nogil:
    """
    Frees the memory allocated for a CProcess instance.

    Parameters:
        process (CProcess*): The CProcess instance to be freed.
    """
    if not process:
        return
    
    if process[0].loaded_modules:
        free(process[0].loaded_modules)
    if process[0].image_filename:
        free(process[0].image_filename)
    free(process)
