from VirtualMemoryToolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from VirtualMemoryToolkit.memory.memory_manager cimport CMemoryManager, CMemoryManager_init, CMemoryManager_virtual_alloc, CMemoryManager_free, CMemoryManager_virtual_free_all


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

    if notepad_memory_manager:
        CMemoryManager_free(notepad_memory_manager)

    if notepad_apphandle:
        CAppHandle_free(notepad_apphandle)
    notepad_process.terminate()
    return error_count