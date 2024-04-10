

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
    ctypedef int* LPARAM
    ctypedef int BOOL
    ctypedef BOOL (*WNDENUMPROC)(HWND hWnd, LPARAM lParam)
    
    DWORD PROCESS_ALL_ACCESS
    DWORD MEM_COMMIT
    DWORD PAGE_READWRITE
    DWORD PAGE_WRITECOPY
    DWORD PAGE_EXECUTE_READWRITE
    DWORD PAGE_EXECUTE_WRITECOPY
    DWORD PAGE_NOACCESS
    DWORD MEM_DECOMMIT
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


cdef int MAX_MODULES = 1024 # Arbitrarily chosen limit


cdef extern from "tlhelp32.h":
    cdef SIZE_T MAX_MODULE_NAME32 = 255
    cdef SIZE_T MAX_PATH = 260
    ctypedef struct MODULEENTRY32:
        DWORD   dwSize
        DWORD   th32ModuleID
        DWORD   th32ProcessID
        DWORD   GlblcntUsage
        DWORD   ProccntUsage
        PBYTE   modBaseAddr
        DWORD   modBaseSize
        HMODULE hModule
        char*    szModule # size of MAX_MODULE_NAME32
        char*    szExePath # size of MAX_PATH

    ctypedef MODULEENTRY32* LPMODULEENTRY32 

    DWORD TH32CS_SNAPMODULE32
    DWORD TH32CS_SNAPMODULE
    