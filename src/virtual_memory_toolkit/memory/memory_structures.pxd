from libc.stdlib cimport malloc, free
from libc.string cimport strstr, strdup
from virtual_memory_toolkit.handles.handle cimport CAppHandle
from virtual_memory_toolkit.windows.windows_types cimport SIZE_T, HANDLE, LPCVOID, LPVOID, PBYTE
from virtual_memory_toolkit.windows.windows_defs cimport PrivilagedSearchMemoryBytes, PrivilagedMemoryRead, PrivilagedMemoryWrite
from virtual_memory_toolkit.process.process cimport CProcess
from virtual_memory_toolkit.windows.windows_defs cimport MAX_MODULES, MODULEENTRY32

cdef extern from "virtual_memory_toolkit/memory/memory_structures.h":
    ctypedef struct CModule:
        CAppHandle* app_handle
        char* name
        void* base_address
        size_t size
    
    ctypedef struct CVirtualAddress:
        CAppHandle *app_handle
        void* address


cdef inline CModule* CModule_init(CAppHandle* app_handle, char* name, void* base_address, size_t size) nogil:
    """
    Initializes a CModule structure with the given parameters.

    Parameters:
        app_handle (CAppHandle*): The application handle.
        name (char*): The name of the module.
        base_address (void*): The base address of the module.
        size (size_t): The size of the module.

    Returns:
        CModule*: A pointer to the newly created CModule structure.
        Returns NULL if memory allocation fails.
    """
    cdef CModule* module = <CModule*>malloc(sizeof(CModule))
    if not module:
        return NULL  # Memory allocation failed

    module[0].app_handle = app_handle
    module[0].name = name
    module[0].base_address = base_address
    module[0].size = size

    return module

cdef inline CModule* CModule_from_process(CProcess* process, const char* module_sub_string) nogil:
    """
    Create a CModule from a CProcess based on a substring of the module name.

    Parameters:
    process : CProcess*
        A pointer to the CProcess containing the modules.
    module_sub_String : const char*
        The substring to search for within the module names.

    Returns:
    CModule*
        A pointer to a newly created CModule if a matching module is found, or NULL if not.

    This function searches through the MODULEENTRY32 array in the provided CProcess
    for a module whose name contains the specified substring. If such a module is found,
    a new CModule is allocated, initialized with the module's details, and returned.

    If the process, module_sub_String, or process[0].loaded_modules is NULL,
    or if no matching module is found, the function returns NULL.
    """
    if not process:
        return NULL
    
    if not module_sub_string:
        return NULL

    if not process[0].loaded_modules:
        return NULL

    cdef MODULEENTRY32 cur_moduleentry
    cdef void* cur_module_address
    cdef size_t cur_module_size
    cdef char* cur_module_fullname
    cdef CModule* module

    for i in range(MAX_MODULES):
        cur_moduleentry = process[0].loaded_modules[i]

        if not cur_moduleentry.szModule[0]:  # Check if the module entry is empty
            break
        
        cur_module_fullname = cur_moduleentry.szModule
        
        if strstr(cur_module_fullname, module_sub_string) != NULL:
            cur_module_address = cur_moduleentry.modBaseAddr
            cur_module_size = cur_moduleentry.modBaseSize
            
            # Allocate and initialize CModule
            module = <CModule*> malloc(sizeof(CModule))
            if not module:
                return NULL

            module.app_handle = process[0].app_handle  # Assuming CProcess has an app_handle
            module.name = strdup(cur_module_fullname)
            module.base_address = cur_module_address
            module.size = cur_module_size

            return module

    return NULL  # Module not found

cdef inline void CModule_free(CModule* module) nogil:
    """
    Frees the memory and any attributes for the CModule struct.

    Parameters:
        module (CModule*): The module to be freed.

    Note:
        The app_handle attribute is not freed as many modules will share this handle.
    """
    if module:
        if module[0].name:
            free(module[0].name)
        free(module)

cdef inline CVirtualAddress* CVirtualAddress_init(CAppHandle* app_handle, void* address) nogil:
    """
    Initializes a CVirtualAddress structure with the given application handle and address.

    Parameters:
        app_handle (CAppHandle*): The application handle.
        address (void*): The address to initialize the CVirtualAddress with.

    Returns:
        CVirtualAddress*: A pointer to the newly created CVirtualAddress structure.
        Returns NULL if memory allocation fails.
    """
    cdef CVirtualAddress* v_address = <CVirtualAddress*>malloc(sizeof(CVirtualAddress))
    if not v_address:
        return NULL  # Memory allocation failed

    v_address[0].app_handle = app_handle
    v_address[0].address = address

    return v_address

cdef inline CVirtualAddress* CVirtualAddress_from_aob(CAppHandle* app_handle, const void* start_address, const void* end_address, unsigned char* array_of_bytes, size_t length_of_aob) nogil:
    """
    Searches for an array of bytes within a specified memory range and returns a CVirtualAddress.

    Parameters:
        app_handle (CAppHandle*): The application handle.
        start_address (const void*): The start address of the search range.
        end_address (const void*): The end address of the search range.
        array_of_bytes (unsigned char*): The array of bytes to search for.
        length_of_aob (size_t): The length of the array of bytes.

    Returns:
        CVirtualAddress*: A pointer to the newly created CVirtualAddress structure.
        Returns NULL if the search fails or memory allocation fails.
    """
    cdef void* found_address = NULL

    if PrivilagedSearchMemoryBytes(
        <HANDLE>app_handle[0].process_handle, 
        <LPCVOID>start_address,
        <LPCVOID>end_address,
        <PBYTE>array_of_bytes,
        <SIZE_T>length_of_aob,
        &found_address
    ):
        # Failed to find address
        return NULL

    cdef CVirtualAddress* v_address = <CVirtualAddress*>malloc(sizeof(CVirtualAddress))
    if not v_address:
        return NULL  # Memory allocation failed

    v_address[0].app_handle = app_handle
    v_address[0].address = found_address

    return v_address

cdef inline CVirtualAddress* CVirtualAddress_from_dynamic(CAppHandle* app_handle, CModule* module, void* offset) nogil:
    """
    Creates a CVirtualAddress from a static offset within a module.

    Parameters:
        app_handle (CAppHandle*): The application handle.
        module (CModule*): The module containing the base address.
        offset (void*): The offset within the module.

    Returns:
        CVirtualAddress*: A pointer to the newly created CVirtualAddress structure.
        Returns NULL if memory allocation fails.
    """
    
    cdef CVirtualAddress* v_address = <CVirtualAddress*>malloc(sizeof(CVirtualAddress))
    if not v_address:
        return NULL  # Memory allocation failed

    cdef char* module_base_address = <char*>module[0].base_address
    cdef ptrdiff_t module_offset = <ptrdiff_t>offset
    cdef char* final_address = module_base_address + module_offset

    v_address[0].app_handle = app_handle
    v_address[0].address = <void*>final_address

    return v_address

cdef inline void CVirtualAddress_offset(CVirtualAddress* virtual_address, long long offset) nogil:
    """
    Changes the CVirtualAddress address by an offset.

    Parameters:
        virtual_address (CVirtualAddress*): Address that will be changed by offset.
        offset (long long): Offset to be added to the address.
    
    """
    virtual_address[0].address = <void*>((<unsigned long long>virtual_address[0].address) + offset)
    return

cdef inline bint CVirtualAddress_read_float32(const CVirtualAddress* virtual_address, float* out_float32) nogil:
    """
    Reads a 32-bit float from the given virtual address and stores it in out_float.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_float32 (float*): Pointer to store the read 32-bit float value.

    Returns:
        bint: 0 on success, 1 on failure.
    """
    # Attempt to read a 32-bit float from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_float32,
        sizeof(float)  # 32-bit float
    )
    
    return bytes_read != sizeof(float)

cdef inline bint CVirtualAddress_read_float32_offset(const CVirtualAddress* virtual_address, float* out_float32, long long offset) nogil:
    """
    Reads a 32-bit float from the given virtual address + offset and stores it in out_float32.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual base address.
        out_float (float*): Pointer to store the read 32-bit float value.
        offset (long long): offset from base address to read from
    Returns:
        bint: 0 on success, 1 on failure.
    """
    
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    # Attempt to read a 32-bit float from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPVOID>out_float32,
        sizeof(float)  # 32-bit float
    )
    
    return bytes_read != sizeof(float)

cdef inline bint CVirtualAddress_write_float32(const CVirtualAddress* virtual_address, const float write_float32) nogil:
    """
    Writes a 32-bit float value to the address specified by the CVirtualAddress structure.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual address where the float value will be written.
        write_float32 (float): The 32-bit float value to write.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPCVOID>&write_float32,
        sizeof(float)
    )
    return 0 if bytes_written == sizeof(float) else 1

cdef inline bint CVirtualAddress_write_float32_offset(const CVirtualAddress* virtual_address, const float write_float32, long long offset) nogil:
    """
    Writes a 32-bit float value to the virtual address + offset.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual base address.
        write_float32 (float): The 32-bit float value to write.
        offset (long long): Offset from the base address to write to.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPCVOID>&write_float32,
        4
    )
    return bytes_written != 4

cdef inline bint CVirtualAddress_read_float64(const CVirtualAddress* virtual_address, double* out_float64) nogil:
    """
    Reads a 64-bit float (double) from the given virtual address and stores it in out_double.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_float64 (double*): Pointer to store the read 64-bit float value.

    Returns:
        bint: 0 on success, 1 on failure.
    """
    # Attempt to read a 64-bit float from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_float64,
        sizeof(double)  # 64-bit float
    )
    
    if bytes_read != sizeof(double):
        return 1  # Failed to read the expected number of bytes

    return 0  # Success

cdef inline bint CVirtualAddress_read_float64_offset(const CVirtualAddress* virtual_address, double* out_float64, long long offset) nogil:
    """
    Reads a 64-bit float from the given virtual address + offset and stores it in out_float64.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual base address.
        out_float64 (double*): Pointer to store the read 64-bit float value.
        offset (long long): offset from base address to read from
    Returns:
        bint: 0 on success, 1 on failure.
    """
    
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    # Attempt to read a 64-bit float from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPVOID>out_float64,
        8
    )
    
    return bytes_read != 8

cdef inline bint CVirtualAddress_write_float64(const CVirtualAddress* virtual_address, const double write_float64) nogil:
    """
    Writes a 64-bit float (double) to the address specified by the CVirtualAddress structure.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual address where the float value will be written.
        write_float64 (double): The 64-bit float value to write.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPCVOID>&write_float64,
        sizeof(double)  # 64-bit float
    )
    
    return 0 if bytes_written == sizeof(double) else 1

cdef inline bint CVirtualAddress_write_float64_offset(const CVirtualAddress* virtual_address, const double write_float64, long long offset) nogil:
    """
    Writes a 64-bit float value to the virtual address + offset.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual base address.
        write_float64 (float): The 64-bit float value to write.
        offset (long long): Offset from the base address to write to.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPCVOID>&write_float64,
        8
    )
    return bytes_written != 8

cdef inline bint CVirtualAddress_read_int8(const CVirtualAddress* virtual_address, char* out_int8) nogil:
    """
    Reads an 8-bit integer from the given virtual address and stores it in out_int8.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_int8 (char*): Pointer to store the read 8-bit integer value.

    Returns:
        BYTE: 0 on success, 1 on failure.
    """
    # Attempt to read an 8-bit integer from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_int8,
        <unsigned long long>1
    )
    
    return bytes_read != 1

cdef inline bint CVirtualAddress_read_int8_offset(const CVirtualAddress* virtual_address, char* out_int8, long long offset) nogil:
    """
    Reads an 8-bit int from the given virtual address + offset and stores it in out_int8.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual base address.
        out_int8 (char*): Pointer to store the read 8-bit int value.
        offset (long long): offset from base address to read from
    Returns:
        bint: 0 on success, 1 on failure.
    """
    
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    # Attempt to read a 8-bit int from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPVOID>out_int8,
        1
    )
    
    return bytes_read != 1

cdef inline bint CVirtualAddress_write_int8(const CVirtualAddress* virtual_address, const char write_int8) nogil:
    """
    Writes an 8-bit integer to the address specified by the CVirtualAddress structure.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address where the 8-bit integer value will be written.
        write_int1 (const char): The 8-bit integer value to write.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPCVOID>&write_int8,
        <unsigned long long>1  
    )
    
    return bytes_written != 1

cdef inline bint CVirtualAddress_write_int8_offset(const CVirtualAddress* virtual_address, const char write_int8, long long offset) nogil:
    """
    Writes a 8-bit float value to the virtual address + offset.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual base address.
        write_int8 (const char): The 8-bit int value to write.
        offset (long long): Offset from the base address to write to.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPCVOID>&write_int8,
        1
    )
    return bytes_written != 1

cdef inline bint CVirtualAddress_read_int16(const CVirtualAddress* virtual_address, short* out_int16) nogil:
    """
    Reads a 16-bit integer from the given virtual address and stores it in out_int16.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_int16 (short*): Pointer to store the read 16-bit integer value.

    Returns:
        BYTE: 0 on success, 1 on failure.
    """
    # Attempt to read an 8-bit integer from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_int16,
        <unsigned long long>2
    )
    
    return bytes_read != 2

cdef inline bint CVirtualAddress_read_int16_offset(const CVirtualAddress* virtual_address, short* out_int16, long long offset) nogil:
    """
    Reads an 16-bit int from the given virtual address + offset and stores it in out_int16.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual base address.
        out_int16 (short*): Pointer to store the read 16-bit int value.
        offset (long long): offset from base address to read from
    Returns:
        bint: 0 on success, 1 on failure.
    """
    
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    # Attempt to read a 8-bit int from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPVOID>out_int16,
        2
    )
    
    return bytes_read != 2

cdef inline bint CVirtualAddress_write_int16(const CVirtualAddress* virtual_address, const short write_int16) nogil:
    """
    Writes an 16-bit integer to the address specified by the CVirtualAddress structure.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address where the 16-bit integer value will be written.
        write_int16 (const short): The 16-bit integer value to write.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPCVOID>&write_int16,
        <unsigned long long>2 
    )
    
    return bytes_written != 2

cdef inline bint CVirtualAddress_write_int16_offset(const CVirtualAddress* virtual_address, const short write_int16, long long offset) nogil:
    """
    Writes a 16-bit float value to the virtual address + offset.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual base address.
        write_int16 (const short): The 16-bit int value to write.
        offset (long long): Offset from the base address to write to.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPCVOID>&write_int16,
        2
    )
    return bytes_written != 2

cdef inline bint CVirtualAddress_read_int32(const CVirtualAddress* virtual_address, int* out_int32) nogil:
    """
    Reads a 32-bit integer from the given virtual address and stores it in out_int32.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_int32 (int*): Pointer to store the read 32-bit integer value.

    Returns:
        BYTE: 0 on success, 1 on failure.
    """
    # Attempt to read an 8-bit integer from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_int32,
        <unsigned long long>4
    )
    
    return bytes_read != 4

cdef inline bint CVirtualAddress_read_int32_offset(const CVirtualAddress* virtual_address, int* out_int32, long long offset) nogil:
    """
    Reads an 32-bit int from the given virtual address + offset and stores it in out_int32.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual base address.
        out_int32 (int*): Pointer to store the read 32-bit int value.
        offset (long long): offset from base address to read from
    Returns:
        bint: 0 on success, 1 on failure.
    """
    
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    # Attempt to read a 8-bit int from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPVOID>out_int32,
        4
    )
    
    return bytes_read != 4

cdef inline bint CVirtualAddress_write_int32(const CVirtualAddress* virtual_address, const int write_int32) nogil:
    """
    Writes an 32-bit integer to the address specified by the CVirtualAddress structure.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address where the 32-bit integer value will be written.
        write_int32 (const int): The 32-bit integer value to write.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPCVOID>&write_int32,
        <unsigned long long>4 
    )
    
    return bytes_written != 4

cdef inline bint CVirtualAddress_write_int32_offset(const CVirtualAddress* virtual_address, const int write_int32, long long offset) nogil:
    """
    Writes a 32-bit float value to the virtual address + offset.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual base address.
        write_int32 (const int): The 32-bit int value to write.
        offset (long long): Offset from the base address to write to.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPCVOID>&write_int32,
        4
    )
    return bytes_written != 4

cdef inline bint CVirtualAddress_read_int64(const CVirtualAddress* virtual_address, long long* out_int64) nogil:
    """
    Reads a 64-bit integer from the given virtual address and stores it in out_int64.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_int64 (long long*): Pointer to store the read 64-bit integer value.

    Returns:
        BYTE: 0 on success, 1 on failure.
    """
    # Attempt to read an 8-bit integer from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_int64,
        <unsigned long long>8
    )
    
    return bytes_read != 8

cdef inline bint CVirtualAddress_read_int64_offset(const CVirtualAddress* virtual_address, long long* out_int64, long long offset) nogil:
    """
    Reads an 64-bit int from the given virtual address + offset and stores it in out_int64.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual base address.
        out_int64 (long long*): Pointer to store the read 64-bit int value.
        offset (long long): offset from base address to read from
    Returns:
        bint: 0 on success, 1 on failure.
    """
    
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPVOID>out_int64,
        8
    )
    
    return bytes_read != 8

cdef inline bint CVirtualAddress_write_int64(const CVirtualAddress* virtual_address, const long long write_int64) nogil:
    """
    Writes an 64-bit integer to the address specified by the CVirtualAddress structure.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address where the 64-bit integer value will be written.
        write_int64 (const long long): The 64-bit integer value to write.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPCVOID>&write_int64,
        <unsigned long long>8 
    )
    
    return bytes_written != 8

cdef inline bint CVirtualAddress_write_int64_offset(const CVirtualAddress* virtual_address, const long long write_int64, long long offset) nogil:
    """
    Writes a 64-bit float value to the virtual address + offset.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual base address.
        write_int64 (const long long): The 64-bit int value to write.
        offset (long long): Offset from the base address to write to.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef unsigned long long address = (<unsigned long long>virtual_address[0].address) + offset

    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>address,
        <LPCVOID>&write_int64,
        8
    )
    return bytes_written != 8

cdef inline void CVirtualAddress_free(CVirtualAddress* virtual_address) nogil:
    """
    Frees the memory for the CVirtualAddress struct.
    
    Note:
        It doesn't free the app_handle attribute as this is shared.
    """
    if virtual_address:
        free(virtual_address)

