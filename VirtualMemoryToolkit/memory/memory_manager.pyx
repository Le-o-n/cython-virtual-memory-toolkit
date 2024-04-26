

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

