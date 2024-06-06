from libc.stdlib cimport malloc, free, calloc 
from libc.string cimport memcpy, memcmp, strstr
from VirtualMemoryToolkit.handles.handle cimport CAppHandle
from VirtualMemoryToolkit.windows.windows_types cimport BYTE, SIZE_T, HANDLE, LPCVOID, LPVOID, PBYTE
from VirtualMemoryToolkit.windows.windows_defs cimport PrivilagedSearchMemoryBytes, PrivilagedMemoryRead, PrivilagedMemoryWrite

cdef extern from "memory_structures.h":
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

    if not PrivilagedSearchMemoryBytes(
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

cdef inline CVirtualAddress* CVirtualAddress_from_static(CAppHandle* app_handle, CModule* module, void* offset) nogil:
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

cdef inline bint CVirtualAddress_read_float32(const CVirtualAddress* virtual_address, float* out_float) nogil:
    """
    Reads a 32-bit float from the given virtual address and stores it in out_float.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_float (float*): Pointer to store the read 32-bit float value.

    Returns:
        bint: 0 on success, 1 on failure.
    """
    # Attempt to read a 32-bit float from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_float,
        sizeof(float)  # 32-bit float
    )
    
    if bytes_read != sizeof(float):
        return 1  # Failed to read the expected number of bytes

    return 0  # Success

cdef inline bint CVirtualAddress_write_float32(CVirtualAddress* virtual_address, const float write_float32) nogil:
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

cdef inline bint CVirtualAddress_read_float64(const CVirtualAddress* virtual_address, double* out_double) nogil:
    """
    Reads a 64-bit float (double) from the given virtual address and stores it in out_double.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_double (double*): Pointer to store the read 64-bit float value.

    Returns:
        bint: 0 on success, 1 on failure.
    """
    # Attempt to read a 64-bit float from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_double,
        sizeof(double)  # 64-bit float
    )
    
    if bytes_read != sizeof(double):
        return 1  # Failed to read the expected number of bytes

    return 0  # Success

cdef inline bint CVirtualAddress_write_float64(CVirtualAddress* virtual_address, const double write_float64) nogil:
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

cdef inline bint CVirtualAddress_read_int1(const CVirtualAddress* virtual_address, unsigned char* out_int1) nogil:
    """
    Reads an 8-bit integer (BYTE) from the given virtual address and stores it in out_int1.

    Parameters:
        virtual_address (const CVirtualAddress*): The virtual address to read from.
        out_int1 (BYTE*): Pointer to store the read 8-bit integer value.

    Returns:
        BYTE: 0 on success, 1 on failure.
    """
    # Attempt to read an 8-bit integer from the specified virtual address
    cdef SIZE_T bytes_read = PrivilagedMemoryRead(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPVOID>out_int1,
        sizeof(BYTE)  # 8-bit integer
    )
    
    if bytes_read != sizeof(BYTE):
        return 1  # Failed to read the expected number of bytes

    return 0  # Success

cdef inline bint CVirtualAddress_write_int1(CVirtualAddress* virtual_address, const unsigned char write_int1) nogil:
    """
    Writes an 8-bit integer (BYTE) to the address specified by the CVirtualAddress structure.

    Parameters:
        virtual_address (CVirtualAddress*): The virtual address where the 8-bit integer value will be written.
        write_int1 (BYTE): The 8-bit integer value to write.

    Returns:
        BYTE: 0 if the write operation is successful, 1 if it fails.
    """
    cdef SIZE_T bytes_written = PrivilagedMemoryWrite(
        virtual_address[0].app_handle[0].process_handle,
        <LPCVOID>virtual_address[0].address,
        <LPCVOID>&write_int1,
        sizeof(BYTE)  
    )
    
    return 0 if bytes_written == sizeof(BYTE) else 1

cdef inline bint CVirtualAddress_read_bytes(CVirtualAddress* virtual_address, unsigned char* out_bytes, size_t num_bytes) nogil:
    
    with gil:
        raise NotImplementedError()

cdef inline bint CVirtualAddress_write_bytes(CVirtualAddress* virtual_address, const unsigned char* write_bytes, size_t num_bytes) nogil:

    with gil:
        raise NotImplementedError()
    # somehow have bytes that don't overwrite like ??

cdef inline void CVirtualAddress_free(CVirtualAddress* virtual_address) nogil:
    """
    Frees the memory for the CVirtualAddress struct.
    
    Note:
        It doesn't free the app_handle attribute as this is shared.
    """
    if virtual_address:
        free(virtual_address)

