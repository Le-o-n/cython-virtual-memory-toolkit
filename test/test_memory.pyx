from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_manager cimport CMemoryManager, CMemoryRegionNode, CMemoryManager_init, CMemoryManager_virtual_alloc, CMemoryManager_free, CMemoryManager_virtual_free_all
from virtual_memory_toolkit.process.process cimport CProcess, CProcess_init, CProcess_free
from virtual_memory_toolkit.memory.memory_structures cimport CModule, CModule_from_process, CModule_free
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_free, CVirtualAddress_from_static, CVirtualAddress_init, CVirtualAddress_read_int8,CVirtualAddress_write_int8 
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress_read_int32 ,CVirtualAddress_read_int32_offset, CVirtualAddress_write_int32, CVirtualAddress_write_int32_offset, CVirtualAddress_offset


import subprocess
import time

def create_notepad_instance():
    """
    Creates a new instance of Notepad by opening it using the specified path.
    """
    notepad_path = "C:\\Windows\\System32\\notepad.exe"
    return subprocess.Popen([notepad_path])

cdef CAppHandle* get_handle_to_notepad():
    """
    Retrieves CAppHandle for Notepad instance.

    Returns:
        CAppHandle* for notepad instance if success.
        NULL if fail.
    """

    cdef const char* notepad_title = b"Notepad"
    
    cdef CAppHandle* app_handle = CAppHandle_from_title_substring(notepad_title)

    return app_handle

cdef CMemoryManager* create_notepad_memory_manager(CAppHandle* notepad_apphandle):
    """
    Creates a CMemoryManager for the notepad instance.

    Parameters:
        notepad_apphandle (CAppHandle*): app handle to the notepad instance.
    
    Returns:
        CMemoryManager* if successful.
        NULL otherwise
    """
    return CMemoryManager_init(notepad_apphandle)
    
cdef int allocate_memory_region(CMemoryManager* memory_manager):
    cdef CVirtualAddress* virtual_memory_region = CMemoryManager_virtual_alloc(memory_manager, <size_t>8)
    if not virtual_memory_region:
        return 1
    return 0

cdef int allocate_memory_regions(CMemoryManager* memory_manager):
    cdef CVirtualAddress* virtual_memory_region = CMemoryManager_virtual_alloc(memory_manager, <size_t>8)
    cdef CVirtualAddress* virtual_memory_region2 = CMemoryManager_virtual_alloc(memory_manager, <size_t>8)

    return not virtual_memory_region or not virtual_memory_region2

cdef int extract_modules(CAppHandle* app_handle) nogil:
    cdef const char* module_substring = "notepad" # notepad.exe
    cdef CModule* module = <CModule*>0
    cdef CProcess* process = CProcess_init(app_handle)

    if not process:
        return 1
    
    module = CModule_from_process(process, module_substring)

    if not module:
        return 1
    CModule_free(module)
    CProcess_free(process)
    return 0
    
cdef int addressing_read_write(CAppHandle* app_handle) nogil:
    cdef const char* module_substring = "KERNEL32" # KERNEL32.dll
    cdef CModule* module = <CModule*>0
    cdef CProcess* process = CProcess_init(app_handle)
    cdef unsigned long long address = 0
    cdef CVirtualAddress* virtual_address
    cdef char read_byte = 0
    cdef char write_byte = 101

    if not process:
        return 1
    
    module = CModule_from_process(process, module_substring)

    if not module:
        CProcess_free(process)
        return 1
    
    address = <unsigned long long>module[0].base_address

    virtual_address = CVirtualAddress_from_static(app_handle, module, <void*>0)
    if not virtual_address:
        CProcess_free(process)
        CModule_free(module)
        return 1

    if CVirtualAddress_read_int8(virtual_address, &read_byte):
        CProcess_free(process)
        CModule_free(module)
        CVirtualAddress_free(virtual_address)
        return 1

    if CVirtualAddress_write_int8(virtual_address, <const char>write_byte):
        CProcess_free(process)
        CModule_free(module)
        CVirtualAddress_free(virtual_address)
        return 1
    
    if CVirtualAddress_read_int8(virtual_address, &read_byte):
        CProcess_free(process)
        CModule_free(module)
        CVirtualAddress_free(virtual_address)
        return 1

    if read_byte != write_byte:
        CProcess_free(process)
        CModule_free(module)
        CVirtualAddress_free(virtual_address)
        return 1

    CProcess_free(process)
    CModule_free(module)
    CVirtualAddress_free(virtual_address)
    return 0

cdef int addressing_read_write_offset(CAppHandle* app_handle) nogil:
    cdef CProcess* process = CProcess_init(app_handle)
    cdef CMemoryManager* mem_manager = CMemoryManager_init(app_handle)
    cdef CVirtualAddress* my_virtual_array = CMemoryManager_virtual_alloc(mem_manager, sizeof(int)*5)
    cdef int read_int = 0

    if CVirtualAddress_write_int32_offset(my_virtual_array, <const int> 100,2*sizeof(int)):
        CVirtualAddress_free(my_virtual_array)
        CProcess_free(process)
        return 1

    if CVirtualAddress_read_int32_offset(my_virtual_array, &read_int, <long long>2*sizeof(int)):
        CVirtualAddress_free(my_virtual_array)
        CProcess_free(process)
        return 1

    if read_int != 100:
        CVirtualAddress_free(my_virtual_array)
        CProcess_free(process)
        return 1
    
    CVirtualAddress_offset(my_virtual_array, <long long>2*sizeof(int))
    
    if CVirtualAddress_read_int32(my_virtual_array, &read_int):
        CVirtualAddress_free(my_virtual_array)
        CProcess_free(process)
        return 1

    if read_int != 100:
        CVirtualAddress_free(my_virtual_array)
        CProcess_free(process)
        return 1

    CVirtualAddress_free(my_virtual_array)
    CProcess_free(process)

    
    return 0




cpdef int run():
    print("\n Running Memory Tests ")
    
    notepad_process = create_notepad_instance()
    
    # Add a slight delay to ensure Notepad has time to open
    time.sleep(1)

    cdef int error_count = 0
    cdef CAppHandle* notepad_apphandle = <CAppHandle*>0
    cdef CMemoryManager* notepad_memory_manager = <CMemoryManager*>0

    
    print("     - get_handle_to_notepad     ... ", end="", flush=True)
    notepad_apphandle = get_handle_to_notepad()
    if not notepad_apphandle:
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")


    print("     - create_notepad_memory_manager ... ", end="", flush=True)
    if notepad_apphandle:
        notepad_memory_manager = create_notepad_memory_manager(notepad_apphandle)
        if not notepad_memory_manager:
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")
    else:
        print("FAILED")
        error_count += 1

    print("     - allocate_memory_region     ... ", end="", flush=True)
    if not notepad_apphandle or not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        if allocate_memory_region(notepad_memory_manager):
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")

    print("     - free_memory_region     ... ", end="", flush=True)
    if not notepad_apphandle or not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        if CMemoryManager_virtual_free_all(notepad_memory_manager):
            print("FAILED")
            error_count += 1
        if notepad_memory_manager[0].memory_regions_head or notepad_memory_manager[0].memory_regions_tail:
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")
         

    print("     - allocate_memory_regions     ... ", end="", flush=True)
    if not notepad_apphandle or not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        if allocate_memory_regions(notepad_memory_manager):
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")

    print("     - free_memory_regions     ... ", end="", flush=True)
    if not notepad_apphandle or not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        if CMemoryManager_virtual_free_all(notepad_memory_manager):
            print("FAILED")
            error_count += 1
        if notepad_memory_manager[0].memory_regions_head or notepad_memory_manager[0].memory_regions_tail:
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")

    
    print("     - module_extraction     ... ", end="", flush=True)
    if not notepad_apphandle or not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        if extract_modules(notepad_apphandle):
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")



    print("     - addressing_read_write     ... ", end="", flush=True)
    if not notepad_apphandle or not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        if addressing_read_write(notepad_apphandle):
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")


    print("     - addressing_read_write_offset     ... ", end="", flush=True)
    if not notepad_apphandle or not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        if addressing_read_write_offset(notepad_apphandle):
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")






    if notepad_memory_manager:
        CMemoryManager_free(notepad_memory_manager)
        
    if notepad_apphandle:
        CAppHandle_free(notepad_apphandle)

    notepad_process.terminate()
    return error_count