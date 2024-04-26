

from libc.stdlib cimport malloc, free, calloc
from libc.string cimport memcpy, memcmp
from libcpp.vector cimport vector
from utils.errors import UnableToAcquireHandle

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
from windows.windows_defs cimport FindProcessFromWindowName

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

cdef inline CAppHandle* CAppHandle_new(CAppHandle* app_handle, char* title_sub_string) nogil:
    cdef FIND_PROCESS_LPARAM window_data = FindProcessFromWindowName(title_sub_string)
    app_handle.window_handle = window_data.out_window_handle
    app_handle.process_handle = window_data.out_all_access_process_handle
    app_handle.pid = window_data.out_pid
    app_handle.window_title = window_data.out_full_window_name

    return app_handle


cdef inline void CAppHandle_dealloc(CAppHandle* app_handle):
    free(app_handle[0].window_title)
    free(app_handle)