from libc.stdlib cimport malloc, free
from libc.stdint cimport uint8_t, uint32_t, int32_t
from libc.string cimport memcpy
from cpython cimport array



cdef extern from "Windows.h":
    ctypedef unsigned long DWORD
    ctypedef DWORD HANDLE
    ctypedef DWORD HWND
    ctypedef unsigned long ULONG_PTR
    ctypedef ULONG_PTR SIZE_T
    ctypedef char* LPSTR
    ctypedef const char* LPCSTR
    ctypedef const void* LPCVOID
    ctypedef void* LPVOID
    ctypedef Py_UNICODE WCHAR
    ctypedef const WCHAR* LPCWSTR
    ctypedef long* LPARAM
    ctypedef int BOOL
    ctypedef BOOL (*WNDENUMPROC)(HWND hWnd, LPARAM lParam)

    cdef unsigned long PROCESS_ALL_ACCESS

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

cdef struct EnumWindowCallbackLParam:
    char* in_window_name
    HWND out_window_handle
    DWORD out_pid
    HANDLE out_all_access_process_handle
    char* out_full_window_name

cdef BOOL enum_window_match_callback(HWND hWnd, LPARAM lparam) noexcept:
    cdef EnumWindowCallbackLParam* data = <EnumWindowCallbackLParam*>lparam
    cdef int length = GetWindowTextLengthA(hWnd)
    cdef char* text_buffer = <char*>malloc(sizeof(char) * (length + 1))
    cdef DWORD target_pid = 0
    GetWindowTextA(hWnd, text_buffer, length + 1);
    
    if (length != 0 and IsWindowVisible(hWnd)):
        if data.in_window_name in text_buffer:
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

    data.in_window_name = window_name
    data.out_all_access_process_handle = 0
    data.out_pid = 0
    data.out_window_handle = 0
    EnumWindows(enum_window_match_callback, <LPARAM>&data)

    return data

cdef HANDLE get_process_handle_from_window_name(const char* windowName) :
    cdef HWND gameWindow = FindWindowA(<LPCSTR>0, windowName)
    cdef DWORD gameProcessId = 0
    GetWindowThreadProcessId(gameWindow, &gameProcessId)
    CloseHandle(gameWindow)
    return OpenProcess(PROCESS_ALL_ACCESS, False, gameProcessId)

cdef int read_process_memory(
    HANDLE process_handle, 
    LPCVOID base_address,
    LPVOID read_buffer, 
    SIZE_T number_of_bytes
):
    cdef SIZE_T read_bytes = 0
    ReadProcessMemory(
        process_handle, 
        base_address, 
        read_buffer, 
        number_of_bytes, 
        &read_bytes
    )
    return read_bytes

cdef int write_process_memory(
    HANDLE process_handle,
    LPVOID base_address,
    LPCVOID write_buffer,
    SIZE_T number_of_bytes
):
    cdef SIZE_T written_bytes = 0
    WriteProcessMemory(
        process_handle,
        base_address, 
        write_buffer, 
        number_of_bytes, 
        &written_bytes
    )
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

        if is_verbose:
            print("=======================================")
            print(" Window name    = ", self._window_name)
            print(" Process handle = ", self._process_handle)
            print(" Window handle  = ", self._window_handle)
            print(" PID            = ", self._pid)
            print("=======================================")

        if self._process_handle == 0:
            error_code = GetLastError()  
            if error_code == 5:
                raise RuntimeError("Unable to get a privilaged handle to target process, please re-run using administrator :)")  
            raise RuntimeError("Unable to get a privilaged handle to target process, unknown error. Error code: " + str(error_code) + ". You can find the reason for the error by querying the error code here: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes")

    def __dealloc__(self):
        CloseHandle(self._process_handle)
        self._process_handle = 0

        free(self._window_name)
        
    def read_memory_bytes(
        self, 
        unsigned long address, 
        int bytes_to_read
    ) -> bytes:
        
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

    def write_memory_bytes(
        self, 
        unsigned long address, 
        bytes bytes_to_write
    ) -> None:
        
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

    def read_memory_float32(self, unsigned long address) -> float:
        # Allocate buffer for reading memory
        cdef void* read_buffer = <void*> malloc(sizeof(float))
        if not read_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Read process memory into the buffer
        
        if not read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>sizeof(float)):
            free(read_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to read process memory.")

        # Convert the buffer to a float
        cdef float result
        memcpy(&result, read_buffer, sizeof(float))

        # Free the allocated memory
        free(read_buffer)

        # Return the float result
        return result
    
    def read_memory_float64(self, unsigned long address) -> double:
        # Allocate buffer for reading memory
        cdef void* read_buffer = <void*> malloc(sizeof(double))
        if not read_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Read process memory into the buffer
        
        if not read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>sizeof(double)):
            free(read_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to read process memory.")

        # Convert the buffer to a float
        cdef double result
        memcpy(&result, read_buffer, sizeof(double))

        # Free the allocated memory
        free(read_buffer)

        # Return the float result
        return result
    
    def read_memory_int32(self, unsigned long address) -> int:
        # Allocate buffer for reading memory
        cdef void* read_buffer = <void*> malloc(sizeof(int32_t))
        if not read_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Read process memory into the buffer
        
        if not read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>sizeof(int32_t)):
            free(read_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to read process memory.")

        # Convert the buffer to a float
        cdef int result
        memcpy(&result, read_buffer, sizeof(int32_t))

        # Free the allocated memory
        free(read_buffer)

        # Return the float result
        return result
    
    def read_memory_uint32(self, unsigned long address) -> int:
        # Allocate buffer for reading memory
        cdef void* read_buffer = <void*> malloc(sizeof(int32_t))
        if not read_buffer:
            raise MemoryError("Failed to allocate memory buffer.")

        # Read process memory into the buffer
        
        if not read_process_memory(self._process_handle, <LPCVOID>address, <LPVOID>read_buffer, <SIZE_T>sizeof(uint32_t)):
            free(read_buffer)  # Ensure to free allocated memory in case of failure
            raise OSError("Failed to read process memory.")

        # Convert the buffer to a float
        cdef unsigned int result
        memcpy(&result, read_buffer, sizeof(uint32_t))

        # Free the allocated memory
        free(read_buffer)

        # Return the float result
        return result

    @property
    def window_handle(self) -> int:
        return self._window_handle
    
    @property
    def process_handle(self) -> int:
        return self._process_handle

    @property
    def pid(self) -> int:
        return self._pid    

