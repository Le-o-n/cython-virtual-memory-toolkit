cdef unsigned long PROCESS_ALL_ACCESS = 0x001FFFFF

cdef extern from "Windows.h":
    ctypedef unsigned long DWORD
    ctypedef DWORD HANDLE
    ctypedef DWORD HWND
    ctypedef unsigned long ULONG_PTR
    ctypedef ULONG_PTR SIZE_T
    ctypedef const char* LPCSTR
    ctypedef const void* LPCVOID
    ctypedef void* LPVOID
    ctypedef Py_UNICODE WCHAR
    ctypedef const WCHAR* LPCWSTR
    ctypedef long* LPARAM
    ctypedef int BOOL
    
    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId)
    HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName)
    int GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId)
    int CloseHandle(HANDLE handle)
    BOOL ReadProcessMemory(
        HANDLE hProcess, 
        LPCVOID lpBaseAddress, 
        LPVOID lpBuffer, 
        SIZE_T nSize, 
        SIZE_T* out_lpNumberOfBytesRead
    )
    BOOL WriteProcessMemory(
        HANDLE  hProcess,
        LPVOID  lpBaseAddress,
        LPCVOID lpBuffer,
        SIZE_T  nSize,
        SIZE_T  *lpNumberOfBytesWritten
    )

cdef HANDLE get_process_handle(const char* windowName) :
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
    ReadProcessMemory(process_handle, base_address, read_buffer, number_of_bytes, &read_bytes)
    return read_bytes

cdef int write_process_memory(
    HANDLE process_handle,
    LPVOID base_address,
    LPCVOID write_buffer,
    SIZE_T number_of_bytes
):
    cdef SIZE_T written_bytes = 0
    WriteProcessMemory(process_handle, base_address, write_buffer, number_of_bytes, &written_bytes)
    return written_bytes

cdef class WindowHandle:
    cdef HANDLE _process_handle
    cdef const char* window_name

    def __cinit__(self, const char* window_name):
        self.window_name = window_name
        self._process_handle = get_process_handle(window_name)

    def __dealloc__(self):
        CloseHandle(self._process_handle)
        self._process_handle = 0
        

    def get_handle(self) -> int:
        return self._process_handle
