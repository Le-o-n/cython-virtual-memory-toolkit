from libc.stdlib cimport malloc, free
from libc.stdint cimport uintptr_t, uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t
from libc.string cimport memcpy
from cpython cimport array

cdef extern from "Windows.h":
    ctypedef unsigned int DWORD
    ctypedef unsigned int* PDWORD
    ctypedef unsigned short WORD
    ctypedef DWORD HANDLE
    ctypedef DWORD HWND
    ctypedef unsigned long ULONG_PTR
    ctypedef ULONG_PTR SIZE_T
    ctypedef char* LPSTR
    ctypedef const char* LPCSTR
    ctypedef const void* LPCVOID
    ctypedef void* LPVOID
    ctypedef void* PVOID
    ctypedef Py_UNICODE WCHAR
    ctypedef const WCHAR* LPCWSTR
    ctypedef long* LPARAM
    ctypedef int BOOL
    ctypedef BOOL (*WNDENUMPROC)(HWND hWnd, LPARAM lParam)
    
    cdef unsigned long PROCESS_ALL_ACCESS
    cdef DWORD PAGE_EXECUTE_READWRITE

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

    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId)
    HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName)
    int GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId)
    int CloseHandle(HANDLE handle)
    BOOL ReadProcessMemory(HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T* out_lpNumberOfBytesRead)
    BOOL WriteProcessMemory(HANDLE  hProcess, LPVOID lpBaseAddress, LPCVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesWritten)
    int GetWindowTextLengthA(HWND hWnd)
    int GetWindowTextA(HWND  hWnd, LPSTR out_lpString, int nMaxCount)
    BOOL EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam)
    BOOL IsWindowVisible(HWND hWnd)
    DWORD GetLastError()
    BOOL VirtualProtectEx(HANDLE hProcess, LPVOID lpAddress, SIZE_T dwSize, DWORD flNewProtect,PDWORD out_lpflOldProtect)
    SIZE_T VirtualQueryEx(HANDLE hProcess, LPCVOID lpAddress, PMEMORY_BASIC_INFORMATION out_lpBuffer, SIZE_T dwLength)


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
    data.out_all_access_process_handle = 0
    data.out_pid = 0
    data.out_window_handle = 0
    EnumWindows(enum_window_match_callback, <LPARAM>&data)

    return data

cdef int read_process_memory(HANDLE process_handle, LPCVOID base_address,LPVOID read_buffer, SIZE_T number_of_bytes):

    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        base_address,
        number_of_bytes,
        PAGE_EXECUTE_READWRITE,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        raise MemoryError("Unknown error, cannot modify virtual memory page protection!")
     
    cdef SIZE_T read_bytes = 0
    ReadProcessMemory(
        process_handle, 
        base_address, 
        read_buffer, 
        number_of_bytes, 
        &read_bytes
    )

    changed_page_protection = VirtualProtectEx(
        process_handle,
        base_address,
        number_of_bytes,
        old_page_protection,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        raise MemoryError("Unknown error, cannot restore page protection!")

    return read_bytes

cdef int write_process_memory(HANDLE process_handle, LPVOID base_address, LPCVOID write_buffer, SIZE_T number_of_bytes):
    
    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        base_address,
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
        base_address,
        number_of_bytes,
        old_page_protection,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        raise MemoryError("Unknown error, cannot restore page protection!")

    return written_bytes

cdef class Application:
    cdef HANDLE _process_handle
    cdef HWND _window_handle
    cdef const char* _window_name
    cdef DWORD _pid
    cdef bint is_verbose

    def __cinit__(self, const char* window_name, bint is_verbose = False):
        

        cdef EnumWindowCallbackLParam window_data = find_process(window_name)
        cdef unsigned long error_code
        self._process_handle = window_data.out_all_access_process_handle
        self._window_handle = window_data.out_window_handle
        self._window_name = window_data.out_full_window_name
        self._pid = window_data.out_pid
        self.is_verbose = is_verbose

        if not self._window_handle:
            if is_verbose:
                print("=================================================")
                print(" Cannot find window name with substring: ", window_name)
                print("=================================================")
            raise MemoryError("Cannot find window with name with substring: ", window_name)

        if not self._process_handle:
            error_code = GetLastError()  
            if error_code == 5:
                if is_verbose:
                    print("=================================================")
                    print(" Unable to get a privilaged handle to target ")
                    print("process, please re-run using administrator :) ")
                    print("=================================================")
                raise RuntimeError("Unable to get a privilaged handle to target process, please re-run using administrator :)")  
            if is_verbose:
                print("=================================================")
                print(" Unable to get a privilaged handle to target ")
                print(" process, unknown error. Error code: " + str(error_code) )
                print("=================================================")
            
            raise RuntimeError("Unable to get a privilaged handle to target process, unknown error. Error code: " + str(error_code) + ". You can find the reason for the error by querying the error code here: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes")

        if is_verbose:
            print("=================================================")
            print(" Window name    = ", self._window_name)
            print(" Process handle = ", self._process_handle)
            print(" Window handle  = ", self._window_handle)
            print(" PID            = ", self._pid)
            print("=================================================")
        
    def __dealloc__(self):
        CloseHandle(self._process_handle)
        CloseHandle(self._window_handle)
        free(self._window_name)
        
    def write_memory_bytes(self, unsigned long address, bytes bytes_to_write) -> None:
        
        cdef char* write_buffer
        cdef SIZE_T num_bytes_written 

        write_buffer = <char*>malloc(sizeof(char) * len(bytes_to_write))

        for i in range(len(bytes_to_write)):
            write_buffer[i] = bytes_to_write[i]

        if not write_buffer:
            raise MemoryError("Failed to allocate memory.")

        num_bytes_written = write_process_memory(self._process_handle, <LPCVOID>address, <LPCVOID>write_buffer, len(bytes_to_write))

        if num_bytes_written != len(bytes_to_write):
            raise MemoryError(f"Error writing to memory. Written bytes: {num_bytes_written}. Bytes instructed to write: {len(bytes_to_write)}.")

        
        free(write_buffer)

        return

    def write_memory_float32(self, unsigned long address, float value) -> None:

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
    
    def write_memory_float64(self, unsigned long address, double value) -> None:

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
        
    cdef void write_memory_int(self, unsigned long address, long long value, int bytes_to_write):
    
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

    cdef void write_memory_uint(self, unsigned long address, unsigned long long value, int bytes_to_write):
    
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

    def write_memory_int8(self, unsigned long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 1)

    def write_memory_int16(self, unsigned long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 2)

    def write_memory_int32(self, unsigned long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 4)

    def write_memory_int64(self, unsigned long address, long value) -> None:
        self.write_memory_int(address, <long long>value, 8)

    def write_memory_uint8(self, unsigned long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 1)

    def write_memory_uint16(self, unsigned long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 2)

    def write_memory_uint32(self, unsigned long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 4)

    def write_memory_uint64(self, unsigned long address, unsigned long value) -> None:
        self.write_memory_uint(address, <unsigned long long>value, 8)

    def read_memory_bytes(self, unsigned long address, int bytes_to_read) -> bytes:
        
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

    def read_memory_float32(self, unsigned long address) -> float:
        
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
    
    def read_memory_float64(self, unsigned long address) -> float:
        
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
    
    cdef long long read_memory_int(self, unsigned long address, unsigned short bytes_in_int):
        
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
    
    def read_memory_int8(self, unsigned long address) -> int:
       return <char>self.read_memory_int(address, 1)

    def read_memory_int16(self, unsigned long address) -> int:
        return <short>self.read_memory_int(address, 2)
    
    def read_memory_int32(self, unsigned long address) -> int:
       return <int>self.read_memory_int(address, 4)
    
    def read_memory_int64(self, unsigned long address) -> int:
       return <long>self.read_memory_int(address, 8)

    def read_memory_uint8(self, unsigned long address) -> int:
       return <unsigned long long>self.read_memory_int(address, 1)

    def read_memory_uint16(self, unsigned long address) -> int:
        return <unsigned long long>self.read_memory_int(address, 2)
    
    def read_memory_uint32(self, unsigned long address) -> int:
       return <unsigned long long>self.read_memory_int(address, 4)
    
    def read_memory_uint64(self, unsigned long address) -> int:
       return <unsigned long long>self.read_memory_int(address, 8)

    @property
    def window_handle(self) -> int:
        return self._window_handle
    
    @property
    def process_handle(self) -> int:
        return self._process_handle

    @property
    def pid(self) -> int:
        return self._pid    


