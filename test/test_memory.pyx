from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_manager cimport CMemoryManager, CMemoryRegionNode, CMemoryManager_init, CMemoryManager_virtual_alloc, CMemoryManager_free, CMemoryManager_virtual_free_all
from virtual_memory_toolkit.process.process cimport CProcess, CProcess_init, CProcess_free
from virtual_memory_toolkit.memory.memory_structures cimport CModule, CModule_from_process, CModule_free
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_free, CVirtualAddress_from_dynamic, CVirtualAddress_init, CVirtualAddress_read_int8,CVirtualAddress_write_int8 
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress_read_int32 , CVirtualAddress_from_aob, CVirtualAddress_read_int32_offset, CVirtualAddress_write_int32, CVirtualAddress_write_int32_offset, CVirtualAddress_offset
from virtual_memory_toolkit.windows.windows_defs cimport GetMemoryRegionsInRange
from virtual_memory_toolkit.windows.windows_types cimport LPCVOID, MEMORY_BASIC_INFORMATION

from libc.stdlib cimport free

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

    virtual_address = CVirtualAddress_from_dynamic(app_handle, module, <void*>0)
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

cdef int region_enumeration(CAppHandle* app_handle):
    cdef CProcess* notepad_process = CProcess_init(app_handle)
    cdef CModule* notepad_module = CModule_from_process(notepad_process, <const char*>"notepad.exe")


    cdef unsigned long long regions
    cdef MEMORY_BASIC_INFORMATION* mem_info_array = GetMemoryRegionsInRange(
        app_handle[0].process_handle, 
        <LPCVOID>notepad_module[0].base_address, 
        <LPCVOID>(<unsigned long long>notepad_module[0].base_address + 4000*5), 
        &regions
    )

    if not mem_info_array:
        return 1

    cdef MEMORY_BASIC_INFORMATION mem_info

    print(regions)
    for i in range(regions):
        mem_info = mem_info_array[i]

        print(hex(<unsigned long long>mem_info.BaseAddress))



cdef int aob_scan(CAppHandle* app_handle):
    
    cdef CProcess* notepad_process = CProcess_init(app_handle)
    
    if not notepad_process:
        return 1
    
    cdef CModule* notepad_module = CModule_from_process(notepad_process, <const char*>"notepad.exe")

    if not notepad_module:
        CProcess_free(notepad_process)
        return 1
    

    cdef unsigned long long start_address = <unsigned long long>notepad_module[0].base_address
    cdef unsigned long long end_address = <unsigned long long>start_address + <unsigned long long>notepad_module[0].size

    cdef unsigned char[25] c_bytes

    py_bytes = [0x38, 0xA2, 0x70, 0xA2, 0xA0, 0xA2, 0xB8, 0xA2, 0xC8, 0xA3, 0xF0, 0xA3, 0x18, 0xA4]

    for i, b in enumerate(py_bytes):
        c_bytes[i] = <unsigned char>b 

    cdef CVirtualAddress* found_address = CVirtualAddress_from_aob(
        app_handle, 
        <const void*>start_address, 
        <const void*>end_address,
        <unsigned char*> &c_bytes, 
        len(py_bytes)
    )

    if found_address:
        print("Found at " + hex(<unsigned long long>found_address[0].address))
    else:
        CModule_free(notepad_module)
        CProcess_free(notepad_process)
        return 1
    

    CModule_free(notepad_module)
    CProcess_free(notepad_process)

    #return valid
    return 0


cpdef int run():
    print("\n Running Memory Tests ")
    
    notepad_process = create_notepad_instance()
    
    # Add a slight delay to ensure Notepad has time to open
    time.sleep(1)

    cdef int error_count = 0
    cdef CAppHandle* notepad_apphandle = <CAppHandle*>0
    cdef CMemoryManager* notepad_memory_manager = <CMemoryManager*>0

    
    print("     - get_handle_to_notepad     ... ")
    notepad_apphandle = get_handle_to_notepad()


    if not notepad_apphandle:
        print("FAILED")
        return 1
    else:
        print("PASSED")


    print("     - create_notepad_memory_manager ... ")
    notepad_memory_manager = create_notepad_memory_manager(notepad_apphandle)
    if not notepad_memory_manager:
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")
    

    print("     - allocate_memory_region     ... ")
    if allocate_memory_region(notepad_memory_manager):
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")

    print("     - free_memory_region     ... ")
    if CMemoryManager_virtual_free_all(notepad_memory_manager):
        print("FAILED")
        error_count += 1
    if notepad_memory_manager[0].memory_regions_head or notepad_memory_manager[0].memory_regions_tail:
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")
         
    print("     - allocate_memory_regions     ... ")
    if allocate_memory_regions(notepad_memory_manager):
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")

    print("     - free_memory_regions     ... ")
    if CMemoryManager_virtual_free_all(notepad_memory_manager):
        print("FAILED")
        error_count += 1
    if notepad_memory_manager[0].memory_regions_head or notepad_memory_manager[0].memory_regions_tail:
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")

    
    print("     - module_extraction     ... ")
    if extract_modules(notepad_apphandle):
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")

    print("     - addressing_read_write     ... ")
    if addressing_read_write(notepad_apphandle):
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")


    print("     - addressing_read_write_offset     ... ")
    
    if addressing_read_write_offset(notepad_apphandle):
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")

    
    print("     - aob_scan          ...")

    if aob_scan(notepad_apphandle):
            print("FAILED")
            error_count += 1
    else:
        print("PASSED")

    print("     - region_enumeration          ...")
    if region_enumeration(notepad_apphandle):
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")

    if notepad_memory_manager:
        CMemoryManager_free(notepad_memory_manager)
        
    if notepad_apphandle:
        CAppHandle_free(notepad_apphandle)

    notepad_process.terminate()

    print("Finished All Tests")
    return error_count