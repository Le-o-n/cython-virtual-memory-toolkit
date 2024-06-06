from VirtualMemoryToolkit.windows.windows_types cimport BYTE, HANDLE, LPVOID, SIZE_T
from VirtualMemoryToolkit.windows.windows_defs cimport VirtualAllocEx, VirtualFreeEx, MEM_COMMIT, MEM_RESERVE, PAGE_EXECUTE_READWRITE, MEM_RELEASE


from VirtualMemoryToolkit.handles.handle cimport CAppHandle, CAppHandle_free
from libc.stdlib cimport malloc, free, calloc 
from libc.string cimport memcpy, memcmp, strstr

cdef extern from "memory_manager.h":

    ctypedef struct CMemoryRegionNode:
        void* address
        SIZE_T size
        CMemoryRegionNode* next
        CMemoryRegionNode* prev
        

    ctypedef struct CMemoryManager:
        CAppHandle* app_handle
        CMemoryRegionNode* memory_regions_head
        CMemoryRegionNode* memory_regions_tail


cdef inline CMemoryRegionNode* CMemoryRegionNode_init() nogil:
    """
    Initializes a new CMemoryRegionNode structure.

    Returns:
        CMemoryRegionNode*: A pointer to the newly created CMemoryRegionNode structure.
        Returns NULL if memory allocation fails.
    """
    cdef CMemoryRegionNode* memory_region = <CMemoryRegionNode*>calloc(1, sizeof(CMemoryRegionNode))
    if not memory_region:
        return NULL  # Memory allocation failed

    return memory_region



cdef inline void CMemoryRegionNode_free(CMemoryRegionNode* node) nogil:
    """
    Frees the memory allocated for a CMemoryRegionNode structure.

    Parameters:
        node (CMemoryRegionNode*): The memory region node to be freed.
    """
    if node:
        free(node)


cdef inline CMemoryManager* CMemoryManager_init(CAppHandle* app_handle) nogil:
    """
    Initializes a new CMemoryManager structure.

    Parameters:
        app_handle (CAppHandle*): The application handle.

    Returns:
        CMemoryManager*: A pointer to the newly created CMemoryManager structure.
        Returns NULL if memory allocation fails.
    """
    cdef CMemoryManager* memory_manager = <CMemoryManager*>malloc(sizeof(CMemoryManager))
    if not memory_manager:
        return NULL  # Memory allocation failed

    memory_manager[0].app_handle = app_handle
    memory_manager[0].memory_regions_head = CMemoryRegionNode_init()
    if not memory_manager[0].memory_regions_head:
        CMemoryManager_free(memory_manager)
        return NULL  # Memory allocation failed

    memory_manager[0].memory_regions_tail = memory_manager[0].memory_regions_head
    return memory_manager

cdef inline CMemoryRegionNode* CMemoryManager_virtual_alloc(CMemoryManager* memory_manager, size_t size) nogil:
    """
    Allocates virtual memory and adds a new memory region node to the memory manager.

    Parameters:
        memory_manager (CMemoryManager*): The memory manager.
        size (size_t): The size of the memory to allocate.

    Returns:
        CMemoryRegionNode*: A pointer to the newly created memory region node.
        Returns NULL if memory allocation fails.
    """
    cdef CMemoryRegionNode* new_memory = CMemoryRegionNode_init()
    if not new_memory:
        return NULL  # Memory allocation failed

    new_memory[0].address = VirtualAllocEx(
        <HANDLE>memory_manager[0].app_handle[0].process_handle,
        <LPVOID>0,
        <SIZE_T>size,
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    )
    if not new_memory[0].address:
        CMemoryRegionNode_free(new_memory)
        return NULL  # Memory allocation failed

    new_memory[0].size = size
    new_memory[0].prev = memory_manager[0].memory_regions_tail
    memory_manager[0].memory_regions_tail.next = new_memory
    memory_manager[0].memory_regions_tail = new_memory

    return new_memory

cdef inline bint CMemoryManager_virtual_free(CMemoryManager* memory_manager, CMemoryRegionNode* memory_region) nogil:
    """
    Frees a specific memory region and removes it from the memory manager's linked list.

    Parameters:
        memory_manager (CMemoryManager*): The memory manager.
        memory_region (CMemoryRegionNode*): The memory region node to be freed.

    Returns:
        bint: 0 on success, 1 on failure.
    """
    if memory_region == memory_manager[0].memory_regions_head:
        return 1  # Cannot free the head node

    if VirtualFreeEx(
        memory_manager[0].app_handle[0].process_handle,
        memory_region[0].address,
        0,
        MEM_RELEASE
    ) == 0:
        return 1  # Failed to free memory

    cdef CMemoryRegionNode* prev_node = memory_region[0].prev
    cdef CMemoryRegionNode* next_node = memory_region[0].next

    if next_node:
        prev_node[0].next = next_node
        next_node[0].prev = prev_node
    else:
        # End of the queue
        prev_node[0].next = NULL
        memory_manager[0].memory_regions_tail = prev_node

    CMemoryRegionNode_free(memory_region)
    return 0



cdef inline void CMemoryManager_virtual_free_all(CMemoryManager* memory_manager) nogil:
    """
    Frees all memory regions managed by the memory manager.

    Parameters:
        memory_manager (CMemoryManager*): The memory manager.
    """
    cdef CMemoryRegionNode* cur_node = memory_manager[0].memory_regions_head
    cdef CMemoryRegionNode* next_node
    while cur_node:
        next_node = cur_node[0].next

        if not CMemoryManager_virtual_free(memory_manager, cur_node):
            pass # failed


        CMemoryRegionNode_free(cur_node)
        cur_node = next_node



cdef inline void CMemoryManager_free(CMemoryManager* memory_manager) nogil:
    """
    Deallocates the memory manager and frees all associated resources.

    Parameters:
        memory_manager (CMemoryManager*): The memory manager.
    """
    if memory_manager:
        CMemoryManager_virtual_free_all(memory_manager)
        free(memory_manager)
    