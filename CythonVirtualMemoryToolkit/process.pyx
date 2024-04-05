from libc.stdlib cimport malloc, free, calloc
from libc.stdint cimport uintptr_t, uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t
from libc.string cimport memcpy, memcmp
from cpython cimport array
from libc.string cimport strncpy, strdup
from libcpp.vector cimport vector

#sizeof(char)         # 1
#sizeof(short)        # 2
#sizeof(int)          # 4
#sizeof(long)         # 4
#sizeof(long long)    # 8
#sizeof(float)        # 4
#sizeof(double)       # 8
#sizeof(void*)        # 8

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
    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID)
    BOOL Module32First(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme)
    BOOL Module32Next(HANDLE hSnapshot, LPMODULEENTRY32 out_lpme)

cdef struct EnumWindowCallbackLParam:
        char* in_window_name_substring
        HWND out_window_handle
        DWORD out_pid
        HANDLE out_all_access_process_handle
        char* out_full_window_name

cdef BOOL enum_window_match_callback(HWND hWnd, LPARAM lparam) noexcept:
    cdef EnumWindowCallbackLParam* data = <EnumWindowCallbackLParam*>lparam
    cdef int length = GetWindowTextLengthA(hWnd)
    cdef char* text_buffer = <char*>malloc(sizeof(char) * (length + 1))
    cdef DWORD target_pid = 0
    GetWindowTextA(hWnd, text_buffer, length + 1)
    
    if (length != 0 and IsWindowVisible(hWnd)):
        if data.in_window_name_substring in text_buffer:
            GetWindowThreadProcessId(hWnd, &target_pid)
            data.out_pid = target_pid
            data.out_window_handle = hWnd
            data.out_all_access_process_handle = OpenProcess(
                PROCESS_ALL_ACCESS,
                False,
                target_pid
            )
            data.out_full_window_name = text_buffer
            return False
    
    free(text_buffer)
    return True

cdef EnumWindowCallbackLParam find_process(char* window_name):
    cdef EnumWindowCallbackLParam data
    
    data.in_window_name_substring = window_name
    data.out_all_access_process_handle = <HANDLE>0
    data.out_pid = 0
    data.out_window_handle = <HWND>0
    EnumWindows(enum_window_match_callback, <LPARAM>&data)

    return data

cdef SIZE_T read_process_memory(HANDLE process_handle, LPCVOID base_address,LPVOID out_read_buffer, SIZE_T number_of_bytes) nogil:

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

cdef SIZE_T write_process_memory(HANDLE process_handle, LPVOID base_address, LPCVOID write_buffer, SIZE_T number_of_bytes) nogil:
    
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
        raise MemoryError("Unknown error, cannot restore page protection!")

    return written_bytes

cdef SIZE_T search_memory(HANDLE process, SIZE_T start_address, SIZE_T end_address, PBYTE pattern, SIZE_T pattern_size) nogil:
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
                if not read_process_memory(process, <LPCVOID>current_address, <LPVOID>read_bytes_buffer, pattern_size):
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

cdef MODULEENTRY32* collect_all_module_information(HANDLE snapshot_handle):
    cdef MODULEENTRY32 me32
    cdef BOOL result
    cdef int count = 0
    cdef MODULEENTRY32* modules = <MODULEENTRY32*>calloc(MAX_MODULES, sizeof(MODULEENTRY32))

    if not modules:
        raise MemoryError("Failed to allocate modules array")

    me32.dwSize = sizeof(MODULEENTRY32)
    result = Module32First(snapshot_handle, &me32)

    while result and count < MAX_MODULES:
        memcpy(&modules[count], &me32, sizeof(MODULEENTRY32))  # Copy structure
        
        count += 1
        result = Module32Next(snapshot_handle, &me32)

    return modules

cdef struct MemoryBlock:
    void* process_handle
    void* address
    SIZE_T size

cdef class Application:
    cdef HANDLE _process_handle
    cdef HWND _window_handle
    cdef HANDLE _snapshot32_handle
    cdef char* _window_name
    
    cdef DWORD _pid
    cdef bint is_verbose
    cdef char* _process_image_filename
    cdef MODULEENTRY32* _modules_info
    
    cdef vector[MemoryBlock] _allocated_memory_blocks

    _py_modules_ordered_list: list[tuple[bytes, int]] = [] 
    _py_modules_dict: dict[bytes, int] = {}

    def __cinit__(self, char* window_name_substring, bint is_verbose = False):
        
        cdef EnumWindowCallbackLParam window_data = find_process(window_name_substring)
        cdef unsigned long error_code
        self._process_handle = window_data.out_all_access_process_handle
        self._window_handle = window_data.out_window_handle
        self._window_name = window_data.out_full_window_name
        self._pid = window_data.out_pid
        self.is_verbose = is_verbose

        self._process_image_filename = <char*>malloc(sizeof(char) * MAX_PATH)
        GetProcessImageFileNameA(self._process_handle, self._process_image_filename, sizeof(char) * MAX_PATH)

        self._snapshot32_handle = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE32 | TH32CS_SNAPMODULE, self._pid)

        self._modules_info = collect_all_module_information(self._snapshot32_handle)
        
        if not self._window_handle:
            if is_verbose:
                print("=================================================")
                print(" Cannot find window name with substring: ", window_name_substring)
                print("=================================================")
            raise MemoryError("Cannot find window with name with substring: ", window_name_substring)

        if not self._process_handle:
            error_code = GetLastError()  
            if error_code == 5 or error_code == 6:
                if is_verbose:
                    print("=================================================")
                    print(" Unable to get a privilaged handle to target ")
                    print(" process, please re-run using administrator :) ")
                    print("=================================================")
                raise RuntimeError("Unable to get a privilaged handle to target process, please re-run using administrator :)")  
            if is_verbose:
                print("=================================================")
                print(" Unable to get a privilaged handle to target ")
                print(" process, unknown error. Error code: " + str(error_code) )
                print("=================================================")
            
            raise RuntimeError("Unable to get a privilaged handle to target process, unknown error. Error code: " + str(error_code) + ". You can find the reason for the error by querying the error code here: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes")

        cdef MODULEENTRY32 cur_mod

        for i in range(MAX_MODULES):
            cur_mod = self._modules_info[i]
            if cur_mod.modBaseSize != 0:
                self._py_modules_ordered_list.append(
                    (
                        cur_mod.szModule, 
                        <unsigned long long>cur_mod.modBaseAddr
                    )
                )

                self._py_modules_dict[cur_mod.szModule] = <unsigned long long>cur_mod.modBaseAddr

        self._py_modules_ordered_list.sort(key = lambda x: x[1])

    def search_process_memory(self, SIZE_T start_address, SIZE_T end_address, bytes search_bytes) -> int:
        if not search_bytes:
            raise ValueError("Search bytes must not be empty.")

        cdef size_t num_bytes = len(search_bytes)
        
        cdef PBYTE c_search_bytes = <PBYTE>calloc(num_bytes, sizeof(BYTE))
        if not c_search_bytes:
            raise MemoryError("Cannot allocate memory for search bytes.")
        
        for i in range(num_bytes):
            c_search_bytes[i] = <BYTE>search_bytes[i]

        cdef SIZE_T found_address
        try:
            # Call the search function with the C bytes array
            found_address = search_memory(
                self._process_handle, 
                start_address, 
                end_address, 
                c_search_bytes, 
                num_bytes
            )
        finally:
            # Ensure memory is freed even if the search throws an exception
            free(c_search_bytes)

        return found_address
  
    def write_memory_bytes(self, unsigned long long address, bytes bytes_to_write) -> None:
        
        cdef char* write_buffer
        cdef SIZE_T num_bytes_written 

        write_buffer = <char*>malloc(sizeof(char) * len(bytes_to_write))

        for i in range(len(bytes_to_write)):
            write_buffer[i] = bytes_to_write[i]

        if not write_buffer:
            raise MemoryError("Failed to allocate memory.")

        num_bytes_written = write_process_memory(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, len(bytes_to_write))

        if num_bytes_written != len(bytes_to_write):
            raise MemoryError(f"Error writing to memory. Written bytes: {num_bytes_written}. Bytes instructed to write: {len(bytes_to_write)}.")

        
        free(write_buffer)

        return

    def write_memory_float32(self, unsigned long long address, float value) -> None:

        cdef float c_value = <float>value
    
        # Allocate buffer for writing memory
        cdef void* write_buffer = <void*>malloc(4)  # Size for float is 4 bytes
        if not write_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Copy the Cython/C float value into the buffer
        memcpy(write_buffer, <void*>&c_value, <size_t>4)

        # Write the buffer to process memory
        if not write_process_memory(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>4):
            free(write_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to write to process memory.")

        # Free the allocated memory
        free(write_buffer)
    
    def write_memory_float64(self, unsigned long long address, double value) -> None:

        cdef double c_value = <double>value
    
        # Allocate buffer for writing memory
        cdef void* write_buffer = <void*>malloc(8)  # Size for float is 4 bytes
        if not write_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Copy the Cython/C float value into the buffer
        memcpy(write_buffer, <void*>&c_value, <size_t>8)

        # Write the buffer to process memory
        if not write_process_memory(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>8):
            free(write_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to write to process memory.")

        # Free the allocated memory
        free(write_buffer)
        
    cdef void write_memory_int(self, unsigned long long address, long long value, int bytes_to_write):
    
        # Convert Python int value to Cython/C long long value
        
        # Allocate buffer for writing memory
        cdef void* write_buffer = <void*> malloc(bytes_to_write)
        if not write_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Copy the Cython/C long long value into the buffer
        memcpy(write_buffer, &value, <size_t>bytes_to_write)

        # Write the buffer to process memory
        if not write_process_memory(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>bytes_to_write):
            free(write_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to write to process memory.")

        # Free the allocated memory
        free(write_buffer)

    cdef void write_memory_uint(self, unsigned long long address, unsigned long long value, int bytes_to_write):
    
        # Convert Python int value to Cython/C long long value
        
        # Allocate buffer for writing memory
        cdef void* write_buffer = <void*> malloc(bytes_to_write)
        if not write_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Copy the Cython/C long long value into the buffer
        memcpy(write_buffer, &value, <size_t>bytes_to_write)

        # Write the buffer to process memory
        if not write_process_memory(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>bytes_to_write):
            free(write_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to write to process memory.")

        # Free the allocated memory
        free(write_buffer)

    def write_memory_int8(self, unsigned long long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 1)

    def write_memory_int16(self, unsigned long long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 2)

    def write_memory_int32(self, unsigned long long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 4)

    def write_memory_int64(self, unsigned long long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 8)

    def write_memory_uint8(self, unsigned long long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 1)

    def write_memory_uint16(self, unsigned long long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 2)

    def write_memory_uint32(self, unsigned long long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 4)

    def write_memory_uint64(self, unsigned long long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 8)

    def read_memory_bytes(self, unsigned long long address, int bytes_to_read) -> bytes:
        
        cdef char* read_buffer
        cdef SIZE_T num_bytes_read 
        cdef bytes py_memory

        read_buffer = <char*>malloc(bytes_to_read)
        
        if not read_buffer:
            raise MemoryError("Failed to allocate memory.")

        num_bytes_read = read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, bytes_to_read)

        if num_bytes_read != bytes_to_read:
            raise MemoryError(f"Error reading memory. Read bytes: {num_bytes_read}. Bytes instructed to read: {bytes_to_read}.")

        py_memory = bytes(<char[:bytes_to_read]>read_buffer)
        
        free(read_buffer)

        return py_memory

    def read_memory_float32(self, unsigned long long address) -> float:
        
        # Allocate buffer for reading memory
        cdef void* read_buffer = <void*> malloc(<SIZE_T>4)
        if not read_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Read process memory into the buffer
        
        if not read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>4):
            free(read_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to read process memory.")

        cdef float result
            
        memcpy(&result, read_buffer, <SIZE_T>4)

        # Free the allocated memory
        free(read_buffer)

        # Return the float result
        return result
    
    def read_memory_float64(self, unsigned long long address) -> float:
        
        # Allocate buffer for reading memory
        cdef void* read_buffer = <void*> malloc(<SIZE_T>8)
        if not read_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Read process memory into the buffer
        
        if not read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>8):
            free(read_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to read process memory.")

        cdef double result
            
        memcpy(&result, read_buffer, <SIZE_T>8)

        # Free the allocated memory
        free(read_buffer)

        # Return the float result
        return result
    
    cdef long long read_memory_int(self, unsigned long long address, unsigned short bytes_in_int):
        
        if bytes_in_int > 8:
            raise MemoryError("Too many bytes requested, requested: " + str(bytes_in_int) + ". Maximum is 8.")
        
        # Allocate buffer for reading memory
        cdef void* read_buffer = <void*> malloc(<SIZE_T>bytes_in_int)
        if not read_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Read process memory into the buffer
        
        if not read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>bytes_in_int):
            free(read_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to read process memory.")

        # Convert the buffer to a float
        cdef long long result
        memcpy(&result, read_buffer, <SIZE_T>bytes_in_int)

        # Free the allocated memory
        free(read_buffer)

        # Return the float result
        return result
    
    def read_memory_int8(self, unsigned long long address) -> int:
       return <char>self.read_memory_int(address, 1)

    def read_memory_int16(self, unsigned long long address) -> int:
        return <short>self.read_memory_int(address, 2)
    
    def read_memory_int32(self, unsigned long long address) -> int:
       return <int>self.read_memory_int(address, 4)
    
    def read_memory_int64(self, unsigned long long address) -> int:
       return <long long>self.read_memory_int(address, 8)

    def read_memory_uint8(self, unsigned long long address) -> int:
       return <unsigned char>self.read_memory_int(address, 1)

    def read_memory_uint16(self, unsigned long long address) -> int:
        return <unsigned short>self.read_memory_int(address, 2)
    
    def read_memory_uint32(self, unsigned long long address) -> int:
        return <unsigned int>self.read_memory_int(address, 4)
    
    def read_memory_uint64(self, unsigned long long address) -> int:
       return <unsigned long long>self.read_memory_int(address, 8)

    def alloc_memory(self, unsigned long long size, unsigned long long min_address = 0, unsigned int allocation_type = MEM_COMMIT, unsigned int protection_type = PAGE_EXECUTE_READWRITE) -> int:
        cdef unsigned long long address = <unsigned long long>VirtualAllocEx(
            self._process_handle,
            <void*>min_address,
            <SIZE_T>size,
            <DWORD>allocation_type,
            <DWORD>protection_type
        )

        cdef MemoryBlock mem_block
        mem_block.address = <void*>address
        mem_block.process_handle = <void*>self.process_handle
        mem_block.size = <SIZE_T>size

        self._allocated_memory_blocks.push_back(mem_block)

        return address

    def dealloc_memory(self, unsigned long long address) -> None:
        cdef int i = 0
        cdef SIZE_T mem_size = 0
        cdef char found = 0
        cdef MemoryBlock mem_block

        # Iterate in reverse order to safely remove elements without affecting the iteration
        for i in range(self._allocated_memory_blocks.size() - 1, -1, -1):
            mem_block = self._allocated_memory_blocks.at(i)
            if <SIZE_T>mem_block.address == address:
                # Mark that we've found a matching block
                found = 1
                
                # Save the size before erasing the block
                mem_size = mem_block.size
                
                # Erase the block from the vector
                self._allocated_memory_blocks.erase(self._allocated_memory_blocks.begin() + i)
                
                # Break after the first match since address should be unique
                break

        # Only attempt to free memory if a matching block was found
        if found:
            if not VirtualFreeEx(self._process_handle, <LPVOID>address, mem_size, MEM_DECOMMIT):
                raise MemoryError(f"Cannot deallocate memory at address {hex(address)}")
        else:
            raise ValueError(f"No memory block found at address {hex(address)}")

    def dealloc_all_memory(self):

        cdef MemoryBlock mem_block
        
        for i in range(self._allocated_memory_blocks.size()):
            mem_block = self._allocated_memory_blocks.at(i)
            print(f"Dealocating memory at address {hex(<SIZE_T>mem_block.address)}")
            if not VirtualFreeEx(
                self._process_handle, 
                mem_block.address, 
                mem_block.size, 
                MEM_DECOMMIT
            ):
                raise MemoryError(f"Unable to free allocated memory block at address {hex(<SIZE_T>mem_block.address)}")



    @property
    def window_handle(self) -> int:
        return <unsigned long long>self._window_handle
    
    @property
    def process_handle(self) -> int:
        return <unsigned long long>self._process_handle

    @property
    def pid(self) -> int:
        return self._pid    

    @property
    def modules(self) -> dict[bytes, int]:
        return self._py_modules_dict

    def __str__(self) -> str:
        cdef MODULEENTRY32 cur_mod

        py_str: str = ""
        py_str = py_str + "\n================================================="
        py_str = py_str + "\n|                Application                    |"
        py_str = py_str + "\n================================================="
        py_str = py_str + "\n| Window name      = " + str(<bytes>self._window_name)
        py_str = py_str + "\n| Process handle   = " + str(<unsigned long long>self._process_handle)
        py_str = py_str + "\n| Window handle    = " + str(<unsigned long long>self._window_handle)
        py_str = py_str + "\n| PID              = " + str(self._pid)
        py_str = py_str + "\n| Process filename = " + str(self._process_image_filename)
        py_str = py_str + "\n================================================="
        py_str = py_str + "\n|                 Modules                       |"
        py_str = py_str + "\n================================================="
        

        module_name: bytes
        module_addr: int
        for module_name, module_addr in self._py_modules_ordered_list:
            py_str = py_str + "\n| " + hex(module_addr) + ": " + module_name.decode('utf-8')

        py_str = py_str + "\n================================================="


        return py_str

    def __repr__(self) -> str:
        return self.__str__()

    def __dealloc__(self):


        self.dealloc_all_memory()

        CloseHandle(self._process_handle)
        CloseHandle(self._window_handle)
        free(self._window_name)
        free(self._process_image_filename)
        free(self._modules_info)
