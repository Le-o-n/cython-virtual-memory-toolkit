

#from libc.stdlib cimport malloc, free, calloc
#from libc.string cimport memcpy, memcmp
#from libcpp.vector cimport vector
#from .errors import UnableToAcquireHandle
#
#from .windows.windows_types cimport BYTE
#from .windows.windows_types cimport PBYTE
#from .windows.windows_types cimport QWORD   
#from .windows.windows_types cimport DWORD         
#from .windows.windows_types cimport WORD        
#from .windows.windows_types cimport PDWORD       
#from .windows.windows_types cimport HANDLE
#from .windows.windows_types cimport HWND
#from .windows.windows_types cimport HMODULE
#from .windows.windows_types cimport ULONG_PTR
#from .windows.windows_types cimport SIZE_T
#from .windows.windows_types cimport LPSTR
#from .windows.windows_types cimport LPCSTR
#from .windows.windows_types cimport LPCVOID
#from .windows.windows_types cimport LPVOID
#from .windows.windows_types cimport PVOID
#from .windows.windows_types cimport WCHAR
#from .windows.windows_types cimport LPCWSTR
#from .windows.windows_types cimport LPARAM
#from .windows.windows_types cimport BOOL
#from .windows.windows_types cimport WNDENUMPROC
#from .windows.windows_types cimport MEMORY_BASIC_INFORMATION
#from .windows.windows_types cimport PMEMORY_BASIC_INFORMATION
from .windows.windows_types cimport MODULEENTRY32
#from VirtualMemoryToolkit.windows cimport windows_definitions 
from VirtualMemoryToolkit cimport windows
from windows cimport windows_types

cdef windows_types.BYTE b = 1

#from .windows.windows_defs cimport GetWindowTextLengthA as get_window_text_a
"""


from .windows.windows_defs cimport GetWindowTextA as get_window_text_a
from .windows.windows_defs cimport IsWindowVisible as is_window_visible
from .windows.windows_defs cimport GetWindowThreadProcessId as get_window_thread_process_id
from .windows.windows_defs cimport OpenProcess as open_process
from .windows.windows_defs cimport EnumWindows as enum_windows
from .windows.windows_defs cimport VirtualQueryEx as virtual_query_ex
from .windows.windows_defs cimport VirtualProtectEx as virtual_protect_ex
from .windows.windows_defs cimport ReadProcessMemory as read_process_memory
from .windows.windows_defs cimport WriteProcessMemory as write_process_memory
from .windows.windows_defs cimport GetProcessImageFileNameA as get_process_image_file_name_a
from .windows.windows_defs cimport Module32First as module_32_first
from .windows.windows_defs cimport Module32Next as module_32_next
from .windows.windows_defs cimport CreateToolhelp32Snapshot as create_tool_help_32_snapshot
from .windows.windows_defs cimport GetLastError as get_last_error
from .windows.windows_defs cimport VirtualAllocEx as virtual_alloc_ex
from .windows.windows_defs cimport VirtualFreeEx as virtual_free_ex
from .windows.windows_defs cimport CloseHandle as close_handle
from .windows.windows_defs cimport PrivilagedMemoryRead as privilaged_memory_read
from .windows.windows_defs cimport PrivilagedMemoryWrite as privilaged_memory_write
from .windows.windows_defs cimport PrivilagedSearchMemoryBytes as privilaged_memory_search_bytes

from .windows.windows_defs cimport MAX_PATH
from .windows.windows_defs cimport TH32CS_SNAPMODULE32
from .windows.windows_defs cimport TH32CS_SNAPMODULE
from .windows.windows_defs cimport MAX_MODULES
from .windows.windows_defs cimport PROCESS_ALL_ACCESS
from .windows.windows_defs cimport MEM_COMMIT
from .windows.windows_defs cimport PAGE_READWRITE
from .windows.windows_defs cimport PAGE_WRITECOPY
from .windows.windows_defs cimport PAGE_EXECUTE_READWRITE
from .windows.windows_defs cimport PAGE_EXECUTE_WRITECOPY
from .windows.windows_defs cimport PAGE_NOACCESS
from .windows.windows_defs cimport MEM_DECOMMIT



#sizeof(char)         # 1
#sizeof(short)        # 2
#sizeof(int)          # 4
#sizeof(long)         # 4
#sizeof(long long)    # 8
#sizeof(float)        # 4
#sizeof(double)       # 8
#sizeof(void*)        # 8
cdef struct EnumWindowCallbackLParam:
    char* in_window_name_substring
    HWND out_window_handle
    DWORD out_pid
    HANDLE out_all_access_process_handle
    char* out_full_window_name

cdef BOOL enum_window_match_callback(HWND hWnd, LPARAM lparam) noexcept:
    cdef EnumWindowCallbackLParam* data = <EnumWindowCallbackLParam*>lparam
    cdef int length = get_window_text_length_a(hWnd)
    cdef char* text_buffer = <char*>malloc(sizeof(char) * (length + 1))
    cdef DWORD target_pid = 0
    get_window_text_a(hWnd, text_buffer, length + 1)
    
    if (length != 0 and is_window_visible(hWnd)):
        if data.in_window_name_substring in text_buffer:
            get_window_thread_process_id(hWnd, &target_pid)
            data.out_pid = target_pid
            data.out_window_handle = hWnd
            data.out_all_access_process_handle = open_process(
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
    enum_windows(enum_window_match_callback, <LPARAM>&data)

    return data


cdef MODULEENTRY32* collect_all_module_information(HANDLE snapshot_handle):
    cdef MODULEENTRY32 me32
    cdef BOOL result
    cdef int count = 0
    cdef MODULEENTRY32* modules = <MODULEENTRY32*>calloc(MAX_MODULES, sizeof(MODULEENTRY32))

    if not modules:
        raise MemoryError("Failed to allocate modules array")

    me32.dwSize = sizeof(MODULEENTRY32)
    result = module_32_first(snapshot_handle, &me32)

    while result and count < MAX_MODULES:
        memcpy(&modules[count], &me32, sizeof(MODULEENTRY32))  # Copy structure
        
        count += 1
        result = module_32_next(snapshot_handle, &me32)

    return modules

cdef struct MemoryBlock:
    void* process_handle
    void* address
    SIZE_T size

cdef class AppHandle:
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

    @staticmethod
    def from_window_name(char* window_name_substring, bint is_verbose = False) -> AppHandle:
        cdef AppHandle app = AppHandle.__new__(AppHandle)
        cdef unsigned long error_code
        
        cdef EnumWindowCallbackLParam window_data = find_process(window_name_substring)
        if not window_data.out_window_handle:
            raise UnableToAcquireHandle(f"Unable to find window with substring {window_name_substring}")
        app._process_handle = window_data.out_all_access_process_handle
        app._window_handle = window_data.out_window_handle
        app._window_name = window_data.out_full_window_name
        app._pid = window_data.out_pid
        app.is_verbose = is_verbose

        app._process_image_filename = <char*>malloc(
            sizeof(char) * MAX_PATH
        )

        get_process_image_file_name_a(
            app._process_handle, 
            app._process_image_filename,
            sizeof(char) * MAX_PATH
        )

        app._snapshot32_handle = create_tool_help_32_snapshot(
            TH32CS_SNAPMODULE32 | TH32CS_SNAPMODULE,
            app._pid
        )

        app._modules_info = collect_all_module_information(
            app._snapshot32_handle
        )
        
        if not app._window_handle:
            if is_verbose:
                print("=================================================")
                print(" Cannot find window name with substring: ", window_name_substring)
                print("=================================================")
            raise MemoryError("Cannot find window with name with substring: ", window_name_substring)

        if not app._process_handle:
            error_code = get_last_error()  
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
            cur_mod = app._modules_info[i]
            if cur_mod.modBaseSize != 0:
                app._py_modules_ordered_list.append(
                    (
                        cur_mod.szModule, 
                        <unsigned long long>cur_mod.modBaseAddr
                    )
                )

                app._py_modules_dict[cur_mod.szModule] = <unsigned long long>cur_mod.modBaseAddr

        app._py_modules_ordered_list.sort(key = lambda x: x[1])

        return app

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
            found_address = privilaged_memory_search_bytes(
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

        num_bytes_written = privilaged_memory_write(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, len(bytes_to_write))

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
        if not privilaged_memory_write(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>4):
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
        if not privilaged_memory_write(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>8):
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
        if not privilaged_memory_write(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>bytes_to_write):
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
        if not privilaged_memory_write(self._process_handle, <LPVOID>address, <LPCVOID>write_buffer, <size_t>bytes_to_write):
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

        num_bytes_read = privilaged_memory_read(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, bytes_to_read)

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
        
        if not privilaged_memory_read(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>4):
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
        
        if not privilaged_memory_read(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>8):
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
        
        if not privilaged_memory_read(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>bytes_in_int):
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
        cdef unsigned long long address = <unsigned long long>virtual_alloc_ex(
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
            if not virtual_free_ex(self._process_handle, <LPVOID>address, mem_size, MEM_DECOMMIT):
                raise MemoryError(f"Cannot deallocate memory at address {hex(address)}")
        else:
            raise ValueError(f"No memory block found at address {hex(address)}")

    def dealloc_all_memory(self):

        cdef MemoryBlock mem_block
        
        for i in range(self._allocated_memory_blocks.size()):
            mem_block = self._allocated_memory_blocks.at(i)
            print(f"Dealocating memory at address {hex(<SIZE_T>mem_block.address)}")
            if not virtual_free_ex(
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

        close_handle(self._process_handle)
        close_handle(self._window_handle)
        free(self._window_name)
        free(self._process_image_filename)
        free(self._modules_info)
"""