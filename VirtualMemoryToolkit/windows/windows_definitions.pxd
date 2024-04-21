from libc.stdlib cimport malloc, free, calloc 
from libc.string cimport memcpy, memcmp

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
from .windows_types cimport PBYTE
from .windows_types cimport BYTE

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
    BOOL VirtualFreeEx(HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD dwFreeType) nogil


cdef extern from "psapi.h":
    DWORD GetProcessImageFileNameA(HANDLE hProcess, LPSTR out_lpImageFileName, DWORD nSize) nogil


cdef extern from "tlhelp32.h":
    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID) nogil
    BOOL Module32First(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme) nogil
    BOOL Module32Next(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme) nogil

cdef SIZE_T MAX_MODULES = 1024  # Arbitrarily chosen limit
cdef extern from "tlhelp32.h":
    
    cdef SIZE_T MAX_MODULE_NAME32   # = 255
    cdef SIZE_T MAX_PATH            # = 260

    DWORD TH32CS_SNAPMODULE32
    DWORD TH32CS_SNAPMODULE



cdef inline SIZE_T PrivilagedMemoryRead(HANDLE process_handle, LPCVOID base_address,LPVOID out_read_buffer, SIZE_T number_of_bytes) nogil:

    cdef MEMORY_BASIC_INFORMATION mbi
    if VirtualQueryEx(process_handle, base_address, &mbi, sizeof(mbi)) == 0:
        with gil:
            raise MemoryError("Failed to query memory information. Address: ", hex(<SIZE_T> base_address))
        

    if mbi.State != MEM_COMMIT or mbi.Protect == PAGE_NOACCESS:
        with gil:
            raise MemoryError("Memory is not committed or is marked as no access. Address: ", hex(<SIZE_T> base_address))
        

    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        PAGE_EXECUTE_READWRITE,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        with gil:
            raise MemoryError("Unknown error, cannot modify virtual memory page protection! Address: ", hex(<SIZE_T> base_address))
        

    cdef SIZE_T read_bytes = 0
    ReadProcessMemory(
        process_handle, 
        base_address, 
        out_read_buffer, 
        number_of_bytes, 
        &read_bytes
    )

    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        old_page_protection,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        with gil:
            raise MemoryError("Unknown error, cannot restore page protection! Address: ", hex(<SIZE_T> base_address))
        
    return read_bytes

cdef inline SIZE_T PrivilagedMemoryWrite(HANDLE process_handle, LPVOID base_address, LPCVOID write_buffer, SIZE_T number_of_bytes) nogil:
    
    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        PAGE_EXECUTE_READWRITE,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        with gil:
            raise MemoryError("Unknown error, cannot modify virtual memory page protection!")
     

    cdef SIZE_T written_bytes = 0
    WriteProcessMemory(
        process_handle,
        base_address, 
        write_buffer, 
        number_of_bytes, 
        &written_bytes
    )

    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        old_page_protection,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        with gil:
            raise MemoryError("Unknown error, cannot restore page protection!")

    return written_bytes

cdef inline SIZE_T PrivilagedSearchMemoryBytes(HANDLE process, SIZE_T start_address, SIZE_T end_address, PBYTE pattern, SIZE_T pattern_size) nogil:
    cdef MEMORY_BASIC_INFORMATION mbi
    cdef SIZE_T address = start_address
    cdef SIZE_T read_bytes
    cdef BOOL found = False
    cdef BYTE* read_bytes_buffer = <BYTE*>calloc(pattern_size, sizeof(BYTE))
    
    cdef SIZE_T region_end
    cdef SIZE_T search_end
    cdef SIZE_T current_address

    if not read_bytes_buffer:
        raise MemoryError("Cannot allocate memory for read buffer")

    while address < end_address:
        if VirtualQueryEx(process, <LPCVOID>address, &mbi, sizeof(mbi)) == 0:
            break  # Failed to query memory information

        if mbi.State == MEM_COMMIT:
            region_end = <SIZE_T>mbi.BaseAddress + mbi.RegionSize
            search_end = min(end_address, region_end) - pattern_size + 1
            current_address = address

            while current_address < search_end:
                if not PrivilagedMemoryRead(process, <LPCVOID>current_address, <LPVOID>read_bytes_buffer, pattern_size):
                    break  # Failed to read memory at current address

                if memcmp(<const void*>pattern, <const void*>read_bytes_buffer, pattern_size) == 0:
                    free(read_bytes_buffer)
                    return current_address  # Pattern found

                current_address += 1
            address = region_end
        else:
            # if region is not committed
            address = <SIZE_T>mbi.BaseAddress + mbi.RegionSize # skip to end of region

    free(read_bytes_buffer)
    return 0  # Pattern not found