from .windows_types cimport MEMORY_BASIC_INFORMATION

cdef SIZE_T privileged_memory_read(HANDLE process_handle, LPCVOID base_address,LPVOID out_read_buffer, SIZE_T number_of_bytes) nogil:

    cdef MEMORY_BASIC_INFORMATION mbi
    if VirtualQueryEx(process_handle, base_address, &mbi, sizeof(mbi)) == 0:
        with gil:
            raise MemoryError("Failed to query memory information. Address: ", hex(<SIZE_T> base_address))
        

    if mbi.State != MEM_COMMIT or mbi.Protect == PAGE_NOACCESS:
        with gil:
            raise MemoryError("Memory is not committed or is marked as no access. Address: ", hex(<SIZE_T> base_address))
        

    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        PAGE_EXECUTE_READWRITE,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        with gil:
            raise MemoryError("Unknown error, cannot modify virtual memory page protection! Address: ", hex(<SIZE_T> base_address))
        

    cdef SIZE_T read_bytes = 0
    ReadProcessMemory(
        process_handle, 
        base_address, 
        out_read_buffer, 
        number_of_bytes, 
        &read_bytes
    )

    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        old_page_protection,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        with gil:
            raise MemoryError("Unknown error, cannot restore page protection! Address: ", hex(<SIZE_T> base_address))
        
    return read_bytes

cdef SIZE_T privilaged_memory_write(HANDLE process_handle, LPVOID base_address, LPCVOID write_buffer, SIZE_T number_of_bytes) nogil:
    
    cdef DWORD old_page_protection
    cdef bint changed_page_protection
    
    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        PAGE_EXECUTE_READWRITE,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        raise MemoryError("Unknown error, cannot modify virtual memory page protection!")
     

    cdef SIZE_T written_bytes = 0
    WriteProcessMemory(
        process_handle,
        base_address, 
        write_buffer, 
        number_of_bytes, 
        &written_bytes
    )

    changed_page_protection = VirtualProtectEx(
        process_handle,
        <LPVOID>base_address,
        number_of_bytes,
        old_page_protection,
        <PDWORD>&old_page_protection
    )

    if not changed_page_protection:
        raise MemoryError("Unknown error, cannot restore page protection!")

    return written_bytes
