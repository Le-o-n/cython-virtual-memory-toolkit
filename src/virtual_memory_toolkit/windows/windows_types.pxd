
cdef extern from "Windows.h":
    ctypedef unsigned char BYTE
    ctypedef unsigned char* PBYTE
    ctypedef unsigned long long QWORD   # 64-bit
    ctypedef unsigned int DWORD         # 32-bit
    ctypedef unsigned short WORD        # 16-bit
    ctypedef unsigned int* PDWORD       
    ctypedef void* HANDLE
    ctypedef HANDLE HWND
    ctypedef HANDLE HMODULE
    ctypedef unsigned long long ULONG_PTR
    ctypedef ULONG_PTR SIZE_T
    ctypedef char* LPSTR
    ctypedef const char* LPCSTR
    ctypedef const void* LPCVOID
    ctypedef void* LPVOID
    ctypedef void* PVOID
    ctypedef Py_UNICODE WCHAR
    ctypedef const WCHAR* LPCWSTR
    ctypedef long long* LPARAM
    ctypedef int BOOL
    ctypedef BOOL (*WNDENUMPROC)(HWND hWnd, LPARAM lParam)
    
    ctypedef struct MEMORY_BASIC_INFORMATION:
        PVOID  BaseAddress
        PVOID  AllocationBase
        DWORD  AllocationProtect
        WORD   PartitionId
        SIZE_T RegionSize
        DWORD  State
        DWORD  Protect
        DWORD  Type

    ctypedef MEMORY_BASIC_INFORMATION* PMEMORY_BASIC_INFORMATION


cdef extern from "virtual_memory_toolkit/windows/windows_types.h":
    ctypedef struct FIND_PROCESS_LPARAM:
        const char* in_window_name_substring
        HWND out_window_handle
        DWORD out_pid
        HANDLE out_all_access_process_handle
        char* out_full_window_name

cdef extern from "tlhelp32.h":

    ctypedef struct MODULEENTRY32:
        DWORD   dwSize
        DWORD   th32ModuleID
        DWORD   th32ProcessID
        DWORD   GlblcntUsage
        DWORD   ProccntUsage
        PBYTE   modBaseAddr
        DWORD   modBaseSize
        HMODULE hModule
        char*    szModule       # size of MAX_MODULE_NAME32
        char*    szExePath      # size of MAX_PATH

    ctypedef MODULEENTRY32* LPMODULEENTRY32 

    
    