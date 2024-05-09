from windows.windows_types cimport BYTE
from memory_structures cimport CVirtualAddress

#cdef struct CMemoryRegion:
#    unsigned long long address
#    unsigned long long size
#
#
#cdef struct CMemoryManager:
#    vector[CMemoryRegion*]* allocated_memory_regions
#
#
#cdef inline CMemoryManager* CMemoryManager_init(CAppHandle* app_handle):
#    cdef CMemoryManager* memory_manager = <CMemoryManager*>malloc(sizeof(CMemoryManager))
#    memory_manager[0].allocated_memory_regions = new vector[CMemoryRegio*]()
#    return memory_manager
#
#cdef inline CMemoryManager_free_all_memory(CMemoryManager* memory_manager):
#    for CMemoryRegion* mem in memory_manager[0].allocated_memory_regions:
#        virtual_free_ex(mem[0].address)
#
#        memory_manager[0].allocated_memory_regions.pop_back()
#
#
#cdef inline void CMemoryManager_dealloc(CMemoryManager* memory_manager):
#    del memory_manager[0].allocated_memory_regions

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