from windows.windows_types cimport BYTE, HANDLE, LPVOID, SIZE_T
from windows.windows_defs cimport VirtualAllocEx, VirtualFreeEx, MEM_COMMIT, MEM_RESERVE, PAGE_EXECUTE_READWRITE, MEM_RELEASE

from memory_structures cimport CVirtualAddress

from handles.handle cimport CAppHandle, CAppHandle_dealloc
from libc.stdlib cimport malloc, free, calloc 
from libc.string cimport memcpy, memcmp, strstr

cdef extern from "memory_manager.h":

    ctypedef struct CMemoryRegionNode:
        SIZE_T address
        SIZE_T size
        CMemoryRegionNode* next
        CMemoryRegionNode* prev
        

    ctypedef struct CMemoryManager:
        CAppHandle* app_handle
        CMemoryRegionNode* memory_regions_head
        CMemoryRegionNode* memory_regions_tail


cdef inline CMemoryRegionNode* CMemoryRegionNode_init():
    cdef CMemoryRegionNode* memory_region = <CMemoryRegionNode*>calloc(1, sizeof(CMemoryRegionNode))
    return memory_region

cdef inline void CMemoryRegionNode_free(CMemoryRegionNode* node):
    free(node)


cdef inline CMemoryManager* CMemoryManager_init(CAppHandle* app_handle):
    cdef CMemoryManager* memory_manager = <CMemoryManager*>malloc(sizeof(CMemoryManager))
    memory_manager[0].app_handle = app_handle
    memory_manager[0].memory_regions_head = CMemoryRegionNode_init()
    return memory_manager

cdef inline CMemoryRegionNode* CMemoryManager_virtual_alloc(CMemoryManager* memory_manager, SIZE_T size):
    cdef CMemoryRegionNode* new_memory = CMemoryRegionNode_init()
    memory_manager[0].memory_regions_tail.next = new_memory

    new_memory[0].address = VirtualAllocEx(
        <HANDLE>memory_manager[0].app_handle[0].process_handle,
        <LPVOID>0,
        <SIZE_T>size,
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    )
    new_memory[0].size = size
    return new_memory

cdef inline bint CMemoryManager_virtual_free(CMemoryManager* memory_manager, CMemoryRegionNode* memory_region):
    
    if memory_region == memory_manager[0].memory_regions_head:
        return

    cdef CMemoryRegionNode* prev_node = memory_region[0].prev
    cdef CMemoryRegionNode* next_node = memory_region[0].next

    if next_node == 0:
        # is end of queue
        prev_node[0].next = 0
        memory_manager[0].memory_regions_tail = prev_node
    else:
        prev_node[0].next = next_node
        next_node[0].prev = prev_node

    return VirtualFreeEx(
        memory_manager[0].app_handle[0].process_handle,
        memory_region[0].address,
        0,
        MEM_RELEASE
    )


cdef inline CMemoryManager_virtual_free_all(CMemoryManager* memory_manager):
    cdef CMemoryRegionNode* cur_node = memory_manager[0].memory_regions_head
    while cur_node[0].next != 0:
        cur_node = cur_node[0].next
        CMemoryRegionNode_free(cur_node[0].prev)
    CMemoryRegionNode_free(cur_node)

cdef inline void CMemoryManager_dealloc(CMemoryManager* memory_manager):
    CMemoryManager_virtual_free_all(memory_manager)
    CAppHandle_dealloc(memory_manager[0].app_handle)
    free(memory_manager)
    
    

