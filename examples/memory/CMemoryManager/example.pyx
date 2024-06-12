from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_manager cimport CMemoryManager, CMemoryManager_free, CMemoryManager_init, CMemoryManager_virtual_alloc, CMemoryManager_virtual_free_address, CMemoryManager_virtual_free, CMemoryManager_virtual_free_all
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_write_int8, CVirtualAddress_read_int8, CVirtualAddress_free

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

    cdef CVirtualAddress* int32 = CMemoryManager_virtual_alloc(mem_manager, <size_t>sizeof(int))
    cdef CVirtualAddress* int1 = CMemoryManager_virtual_alloc(mem_manager, <size_t>10*sizeof(char))
    cdef CVirtualAddress* int32_array = CMemoryManager_virtual_alloc(mem_manager, <size_t>10*sizeof(int))

    CVirtualAddress_write_int8(int1, <const unsigned char>100)
    
    cdef unsigned char read_int1
    CVirtualAddress_read_int8(int1, &read_int1)

    CMemoryManager_virtual_free_address(mem_manager, int32)
    CMemoryManager_virtual_free_all(mem_manager) 

    CMemoryManager_free(mem_manager)
    CAppHandle_free(app_handle)
    return 0
