from libc.stdlib cimport malloc, free, calloc, realloc
from libc.string cimport memcpy, memcmp, strstr
from cython.parallel import prange, parallel, threadid

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
from .windows_types cimport MODULEENTRY32
from .windows_types cimport FIND_PROCESS_LPARAM

cdef extern from "Windows.h":
    DWORD PROCESS_ALL_ACCESS
    DWORD MEM_COMMIT
    DWORD MEM_RESERVE
    DWORD MEM_RELEASE
    DWORD PAGE_READWRITE
    DWORD PAGE_WRITECOPY
    DWORD PAGE_EXECUTE_READWRITE
    DWORD PAGE_EXECUTE_WRITECOPY
    DWORD PAGE_NOACCESS
    DWORD MEM_DECOMMIT
    void* INVALID_HANDLE_VALUE

    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId) nogil
    HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName) nogil
    int GetWindowThreadProcessId(HWND hWnd, PDWORD lpdwProcessId) nogil
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
    SIZE_T MAX_MODULE_NAME32   # = 255
    SIZE_T MAX_PATH            # = 260
    DWORD TH32CS_SNAPMODULE32
    DWORD TH32CS_SNAPMODULE

    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID) nogil
    BOOL Module32First(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme) nogil
    BOOL Module32Next(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme) nogil

cdef extern from "virtual_memory_toolkit/windows/windows_defs.h":
    cdef SIZE_T MAX_MODULES


cdef inline MODULEENTRY32* CollectAllModuleInformation(HANDLE snapshot_handle) nogil:
    cdef MODULEENTRY32 me32
    cdef BOOL result
    cdef int count = 0
    cdef MODULEENTRY32* modules = <MODULEENTRY32*>calloc(MAX_MODULES, sizeof(MODULEENTRY32))

    if not modules:
        with gil:
            raise MemoryError("Failed to allocate modules array")

    me32.dwSize = sizeof(MODULEENTRY32)
    result = Module32First(snapshot_handle, &me32)

    while result and count < MAX_MODULES:
        memcpy(&modules[count], &me32, sizeof(MODULEENTRY32))  # Copy structure
        
        count += 1
        result = Module32Next(snapshot_handle, &me32)

    return modules

cdef inline SIZE_T PrivilagedMemoryRead(HANDLE process_handle, LPCVOID base_address, LPVOID out_read_buffer, SIZE_T number_of_bytes) nogil:
    """
    Reads memory from a specified address in a process's virtual memory, adjusting page protection as necessary.

    Parameters:
        process_handle (HANDLE): The handle to the process whose memory will be read.
        base_address (LPCVOID): The base address from where the memory will be read.
        out_read_buffer (LPVOID): The buffer where the read data will be stored.
        number_of_bytes (SIZE_T): The number of bytes to read.

    Returns:
        SIZE_T: The number of bytes successfully read, or 0 if the operation fails.
    """
    cdef MEMORY_BASIC_INFORMATION mbi
    if VirtualQueryEx(process_handle, base_address, &mbi, sizeof(mbi)) == 0:
        return 0  # Failed to query memory information

    if mbi.State != MEM_COMMIT or mbi.Protect == PAGE_NOACCESS:
        return 0  # Memory is not committed or is marked as no access

    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        PAGE_EXECUTE_READWRITE,
        &old_page_protection
    )

    if not changed_page_protection:
        return 0  # Failed to change page protection

    cdef SIZE_T read_bytes = 0
    if not ReadProcessMemory(
        process_handle, 
        base_address, 
        out_read_buffer, 
        number_of_bytes, 
        &read_bytes
    ):
        # Restore the original page protection before returning
        VirtualProtectEx(
            process_handle,
            <LPVOID>base_address,
            number_of_bytes,
            old_page_protection,
            &old_page_protection
        )
        return 0  # Failed to read memory

    # Restore the original page protection
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        old_page_protection,
        &old_page_protection
    )

    if not changed_page_protection:
        return 0  # Failed to restore page protection

    return read_bytes

cdef inline SIZE_T PrivilagedMemoryWrite(HANDLE process_handle, LPCVOID base_address, LPCVOID write_buffer, SIZE_T number_of_bytes) nogil:
    """
    Writes memory to a specified address in a process's virtual memory, adjusting page protection as necessary.

    Parameters:
        process_handle (HANDLE): The handle to the process whose memory will be written.
        base_address (LPCVOID): The base address where the memory will be written.
        write_buffer (LPCVOID): The buffer containing the data to write.
        number_of_bytes (SIZE_T): The number of bytes to write.

    Returns:
        SIZE_T: The number of bytes successfully written, or 0 if the operation fails.
    """
    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        PAGE_EXECUTE_READWRITE,
        &old_page_protection
    )

    if not changed_page_protection:
        return 0  # Failed to change page protection

    cdef SIZE_T written_bytes = 0
    if not WriteProcessMemory(
        process_handle,
        <LPVOID>base_address, 
        write_buffer, 
        number_of_bytes, 
        &written_bytes
    ):
        # Restore the original page protection before returning
        VirtualProtectEx(
            process_handle,
            <LPVOID>base_address,
            number_of_bytes,
            old_page_protection,
            &old_page_protection
        )
        return 0  # Failed to write memory

    # Restore the original page protection
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        old_page_protection,
        &old_page_protection
    )

    if not changed_page_protection:
        return 0  # Failed to restore page protection

    return written_bytes


cdef inline MEMORY_BASIC_INFORMATION* GetMemoryRegionsInRange(
    HANDLE process, 
    LPCVOID start_address, 
    LPCVOID end_address,
    unsigned long long *out_found_regions
) nogil:
    cdef MEMORY_BASIC_INFORMATION mbi
    cdef unsigned long information_buffer_size
    cdef LPCVOID current_address = start_address
    cdef unsigned long long total_regions = 0
    cdef MEMORY_BASIC_INFORMATION *regions = NULL
    cdef MEMORY_BASIC_INFORMATION *temp_regions = NULL
    cdef unsigned long long regions_capacity = 128  # Initial capacity for regions array
    cdef unsigned long long i

    regions = <MEMORY_BASIC_INFORMATION*>malloc(regions_capacity * sizeof(MEMORY_BASIC_INFORMATION))
    if regions == NULL:
        return NULL

    while current_address < end_address:

        if VirtualQueryEx(process, current_address, &mbi, sizeof(mbi)) == 0:
            current_address = <LPCVOID>(<unsigned long long>current_address + 10)
            continue

        if total_regions >= regions_capacity:
            regions_capacity *= 2
            temp_regions = <MEMORY_BASIC_INFORMATION*>realloc(
                regions, 
                regions_capacity * sizeof(MEMORY_BASIC_INFORMATION)
            )
            if temp_regions == NULL:
                free(regions)
                return NULL
            regions = temp_regions
        
        regions[total_regions] = mbi
        total_regions += 1

        current_address = <LPCVOID>(<unsigned long long>mbi.BaseAddress + mbi.RegionSize)

    if total_regions == 0:
        free(regions)
        out_found_regions[0]=0
        return NULL

    if out_found_regions != NULL:
        out_found_regions[0] = total_regions

    return regions

cdef inline LPVOID PrivilagedSearchMemoryBytes(
    HANDLE process, 
    LPCVOID start_address, 
    LPCVOID end_address, 
    PBYTE pattern, 
    SIZE_T pattern_size
) nogil:
    """
    Searches for a byte pattern within a specified memory range.

    Parameters:
        process (HANDLE): The handle to the process whose memory will be searched.
        start_address (LPCVOID): The start address of the search range.
        end_address (LPCVOID): The end address of the search range.
        pattern (PBYTE): The byte pattern to search for.
        pattern_size (SIZE_T): The size of the byte pattern.
        out_found_address (LPVOID*): Pointer to store the found address if the pattern is found.

    Returns:
        BOOL: 0 if the pattern is found, 1 if it is not found or an error occurs.
    """

    
    cdef unsigned long long found_regions
    cdef MEMORY_BASIC_INFORMATION* memory_regions 
    cdef MEMORY_BASIC_INFORMATION memory_region
    memory_regions = GetMemoryRegionsInRange(
        process,
        start_address,
        end_address,
        &found_regions
    )

    cdef unsigned long long iter_size
    cdef unsigned long long start_region_address
    cdef unsigned long long end_region_address
    cdef BYTE* read_bytes_buffer
    cdef SIZE_T c_i
    cdef SIZE_T c_j

    for c_i in range(found_regions):
        
        memory_region = <MEMORY_BASIC_INFORMATION>memory_regions[c_i]

        if memory_region.State != MEM_COMMIT:
            continue
        
        start_region_address = <unsigned long long>memory_region.BaseAddress
        end_region_address = <unsigned long long>memory_region.BaseAddress + memory_region.RegionSize
        
        read_bytes_buffer = <BYTE*>malloc(
            memory_region.RegionSize * sizeof(BYTE)
        )
        
        if not read_bytes_buffer:
            return NULL 
        
        if PrivilagedMemoryRead(
            process,
            <LPCVOID>start_region_address, 
            <LPVOID>read_bytes_buffer, 
            memory_region.RegionSize
        ) != memory_region.RegionSize:
            free(read_bytes_buffer)
            return NULL 
        
        iter_size = memory_region.RegionSize-pattern_size 

        for c_j in prange(iter_size, nogil=True):
            if memcmp(
                <const void*>(<SIZE_T>read_bytes_buffer + c_j),
                <const void*>pattern,
                pattern_size
            ) == 0:
                with gil:
                    print(f"Thread {threadid()}: Got address = {hex(<size_t>(start_region_address + c_j))}")

                return <LPVOID>(start_region_address + c_j)
        
        free(read_bytes_buffer)

    return NULL   # Pattern not found or error occurred

cdef inline BOOL _FindProcessFromWindowTitleSubstringCallback(HWND hWnd, LPARAM lparam) noexcept nogil:
    cdef FIND_PROCESS_LPARAM* data = <FIND_PROCESS_LPARAM*>lparam
    cdef int length = GetWindowTextLengthA(hWnd)
    cdef char* current_window_title = <char*>malloc(sizeof(char) * (length + 1))
    cdef DWORD target_pid = 0
    cdef bint found_substring = 0

    GetWindowTextA(hWnd, current_window_title, length + 1)
    
    if (length != 0 and IsWindowVisible(hWnd)):

        found_substring = strstr(
            current_window_title, 
            data.in_window_name_substring
        ) != NULL

        if found_substring:
            GetWindowThreadProcessId(hWnd, &target_pid)
            data.out_pid = target_pid
            data.out_window_handle = hWnd
            data.out_all_access_process_handle = OpenProcess(
                PROCESS_ALL_ACCESS,
                False,
                target_pid
            )
            data.out_full_window_name = current_window_title
            return False

    free(current_window_title)
    return True

cdef inline FIND_PROCESS_LPARAM FindProcessFromWindowTitleSubstring(const char* window_name_sub_string) nogil:
    cdef FIND_PROCESS_LPARAM data
    
    data.in_window_name_substring = window_name_sub_string
    data.out_all_access_process_handle = <HANDLE>0
    data.out_pid = 0
    data.out_window_handle = <HWND>0
    EnumWindows(_FindProcessFromWindowTitleSubstringCallback, <LPARAM>&data)

    return data