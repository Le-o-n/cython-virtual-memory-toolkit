from VirtualMemoryToolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from VirtualMemoryToolkit.memory.memory_manager cimport CMemoryManager, CMemoryManager_free, CMemoryManager_init, CMemoryManager_virtual_alloc, CMemoryManager_virtual_free, CMemoryManager_virtual_free_all
from VirtualMemoryToolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_write_float32, CVirtualAddress_read_float32, CVirtualAddress_free

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
    cdef CAppHandle* app_handle = get_handle()
    cdef CMemoryManager* mem_manager = CMemoryManager_init(app_handle)

    cdef CVirtualAddress* int32_array = CMemoryManager_virtual_alloc(mem_manager, <size_t>10*sizeof(float))

    CVirtualAddress_write_float32(int32_array, <float>1.0)
    print("Wrote 1.0f to address " + str(hex(<unsigned long long>int32_array[0].address)))

    cdef float read_float 
    CVirtualAddress_read_float32(int32_array, &read_float)

    print("Read float = " + str(read_float))

    input("Waiting on key press...")

    CMemoryManager_free(mem_manager)
    CAppHandle_free(app_handle)
    return 0
