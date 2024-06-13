from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from libc.string cimport strdup
from libc.stdlib cimport free

cpdef int main():
    cdef CAppHandle* app_handle = <CAppHandle*>NULL
    cdef char* window_title_substring

    while not app_handle:
        py_input = input("Enter window title substring to get handle to (e.g. \"Notepad\").\n: ")
        window_title_substring = strdup(py_input.encode('utf-8'))

        app_handle = CAppHandle_from_title_substring(<const char*>window_title_substring)
        
        if not app_handle:
            print("Cannot get a handle to window with a window title containing \'" + py_input + "\'.")
        else:
            print("Got handle successfully to process with PID of " + str(app_handle[0].pid) + ".")

        free(window_title_substring)

    # Do something with the handle
    # ...

    CAppHandle_free(app_handle)
    return 0
