from handles.handle cimport CAppHandle
from windows.windows_types cimport UBYTE, BYTE

cdef extern from "memory_structures.h":
    ctypedef struct CModule:
       char* name
       void* base_address
       size_t size
    
    ctypedef struct CVirtualAddress:
        CAppHandle *app_handle
        unsigned long long address


cdef inline CModule* CModule_init(char* name, void* base_address, size_t size) nogil:
    pass

cdef inline void CModule_free(CModule* c_module) nogil:
    pass

cdef inline CVirtualAddress* CVirtualAddress_init(CAppHandle* app_handle, unsigned long long address) nogil:
    pass

cdef inline CVirtualAddress* CVirtualAddress_from_aob(CAppHandle* app_handle, UBYTE* array_of_bytes, unsigned long long length) nogil:
    pass

cdef inline CVirtualAddress* CVirtualAddress_from_static(CAppHandle* app_handle, CModule* module, unsigned long long offset) nogil:
    pass

cdef inline float CVirtualAddress_read_float32(CVirtualAddress* virtual_address) nogil:
    pass

cdef inline BYTE CVirtualAddress_write_float32(CVirtualAddress* virtual_address, float write_float32) nogil:
    pass

cdef inline double CVirtualAddress_read_float64(CVirtualAddress* virtual_address) nogil:
    pass

cdef inline BYTE CVirtualAddress_write_float64(CVirtualAddress* virtual_address, double write_float64) nogil:
    pass

cdef inline BYTE CVirtualAddress_read_int1(CVirtualAddress* virtual_address) nogil:
    pass

cdef inline BYTE CVirtualAddress_write_int1(CVirtualAddress* virtual_address, BYTE write_int1) nogil:
    pass

cdef inline void CVirtualAddress_free(CAppHandle* app_handle) nogil:
    pass
