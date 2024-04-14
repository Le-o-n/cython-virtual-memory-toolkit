from .windows_types cimport SIZE_T
from .windows_types cimport DWORD
from .windows_types cimport HANDLE
from .windows_types cimport HWND
from .windows_types cimport LPCSTR
from .windows_types cimport BOOL
from .windows_types cimport LPCVOID
from .windows_types cimport LPVOID
from .windows_types cimport LPSTR
from .windows_types cimport LPARAM
from .windows_types cimport WNDENUMPROC
from .windows_types cimport PMEMORY_BASIC_INFORMATION
from .windows_types cimport MEMORY_BASIC_INFORMATION
from .windows_types cimport PDWORD
from .windows_types cimport LPMODULEENTRY32


cdef extern from "Windows.h":
    DWORD PROCESS_ALL_ACCESS
    DWORD MEM_COMMIT
    DWORD PAGE_READWRITE
    DWORD PAGE_WRITECOPY
    DWORD PAGE_EXECUTE_READWRITE
    DWORD PAGE_EXECUTE_WRITECOPY
    DWORD PAGE_NOACCESS
    DWORD MEM_DECOMMIT

    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId) nogil
    HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName) nogil
    int GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId) nogil
    int CloseHandle(HANDLE handle) nogil
    BOOL ReadProcessMemory(HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T* out_lpNumberOfBytesRead) nogil
    BOOL WriteProcessMemory(HANDLE  hProcess, LPVOID lpBaseAddress, LPCVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesWritten) nogil
    int GetWindowTextLengthA(HWND hWnd) nogil
    int GetWindowTextA(HWND  hWnd, LPSTR out_lpString, int nMaxCount) nogil
    BOOL EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam) nogil
    BOOL IsWindowVisible(HWND hWnd) nogil
    DWORD GetLastError() nogil
    BOOL VirtualProtectEx(HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD flNewProtect,PDWORD out_lpflOldProtect) nogil
    SIZE_T VirtualQueryEx(HANDLE hProcess, LPCVOID lpAddress, PMEMORY_BASIC_INFORMATION out_lpBuffer, SIZE_T dwLength) nogil
    LPVOID VirtualAllocEx(HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD flAllocationType, DWORD flProtect) nogil
    BOOL VirtualFreeEx(HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD dwFreeType)


cdef extern from "psapi.h":
    DWORD GetProcessImageFileNameA(HANDLE hProcess, LPSTR out_lpImageFileName, DWORD nSize) nogil


cdef extern from "tlhelp32.h":
    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID)
    BOOL Module32First(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme)
    BOOL Module32Next(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme)


cdef extern from "tlhelp32.h":
    cdef SIZE_T MAX_MODULES = 1024  # Arbitrarily chosen limit
    cdef SIZE_T MAX_MODULE_NAME32   # = 255
    cdef SIZE_T MAX_PATH            # = 260

    DWORD TH32CS_SNAPMODULE32
    DWORD TH32CS_SNAPMODULE


cdef SIZE_T privileged_memory_read(HANDLE process_handle, LPCVOID base_address,LPVOID out_read_buffer, SIZE_T number_of_bytes) nogil
cdef SIZE_T privilaged_memory_write(HANDLE process_handle, LPVOID base_address, LPCVOID write_buffer, SIZE_T number_of_bytes) nogil