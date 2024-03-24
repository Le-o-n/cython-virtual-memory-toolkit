from libc.stdlib cimport malloc, free

cdef unsigned long PROCESS_ALL_ACCESS = 0x001FFFFF

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

cdef struct EnumWindowCallbackLParam:
    char* window_name
    HANDLE out_handle
    int out_matches

cdef BOOL enum_window_match_callback(HWND hWnd, LPARAM lparam) noexcept:
    cdef EnumWindowCallbackLParam* data = <EnumWindowCallbackLParam*>lparam
    cdef int length = GetWindowTextLengthA(hWnd)
    cdef char* text_buffer = <char*>malloc(sizeof(char) * (length + 1))
    GetWindowTextA(hWnd, text_buffer, length + 1);
    
    if (length != 0 and IsWindowVisible(hWnd)):
        if data.window_name in text_buffer:
            data.out_handle = hWnd
            data.out_matches += 1

    free(text_buffer)

    return True;

cdef HANDLE find_process(char* window_name):
    cdef EnumWindowCallbackLParam data
    data.window_name = window_name
    data.out_matches = 0
    EnumWindows(enum_window_match_callback, <LPARAM>&data);
    return data.out_handle

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

cdef class WindowHandle:
    cdef HANDLE _process_handle
    cdef const char* window_name

    def __cinit__(self, const char* window_name):
        self.window_name = window_name
        self._process_handle = find_process(window_name)
        if self._process_handle == 0:
            raise RuntimeWarning("Unable to get handle to process...")

    def __dealloc__(self):
        CloseHandle(self._process_handle)
        self._process_handle = 0
        

    def get_handle(self) -> int:
        return self._process_handle
