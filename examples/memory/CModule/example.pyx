from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_structures cimport CModule, CModule_free, CModule_from_process
from virtual_memory_toolkit.process.process cimport CProcess, CProcess_new, CProcess_free


from libc.string cimport strdup
from libc.stdlib cimport free

cdef CAppHandle* get_handle():
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
    return app_handle

cpdef int main():
    cdef char* module_substring = "USER32"
    cdef CAppHandle* app_handle = get_handle()
    cdef CProcess* process = CProcess_new(app_handle)
    cdef CModule* module = CModule_from_process(process, <const char*>module_substring)

    if not module:
        print("Cannot get module " + str(module_substring))
    else:
        print("Got valid CModule, " + str(module_substring) + " at address "+ hex(<unsigned long long>module[0].base_address))

    CModule_free(module)
    CProcess_free(process)
    CAppHandle_free(app_handle)
    return 0
