from virtual_memory_toolkit.windows.windows_defs cimport FindWindowA, GetLastError, GetWindowThreadProcessId
from virtual_memory_toolkit.windows.windows_types cimport HWND, LPCSTR, DWORD


cpdef int main():
    cdef char* window_full_title = "Untitled - Notepad"
    cdef HWND hWnd = FindWindowA(<LPCSTR>0, <LPCSTR>window_full_title)
    if not hWnd:
        print("Could not get a windows handle to \`" + window_full_title + "\`. Error code = " + str(GetLastError()))

    cdef DWORD pid
    
    GetWindowThreadProcessId(<HWND>hWnd, &pid)
    if not pid:
        print("Could not get PID. Error code = " + str(GetLastError()))
    else:
        print("PID = " + str(pid))


    return 0
