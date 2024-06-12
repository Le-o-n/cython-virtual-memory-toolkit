from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.process.process cimport CProcess, CProcess_init, CProcess_free


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

cdef CProcess* create_notepad_cprocess(CAppHandle* notepad_apphandle):
    """
    Creates a CProcess for the notepad instance.

    Parameters:
        notepad_apphandle (CAppHandle*): app handle to the notepad instance.
    
    Returns:
        CProcess* if successful.
        NULL otherwise
    """
    return CProcess_init(notepad_apphandle)
    

cpdef int run():
    print("\n Running Process Tests ")
    
    notepad_process = create_notepad_instance()
    
    # Add a slight delay to ensure Notepad has time to open
    time.sleep(1)

    cdef int error_count = 0
    cdef CAppHandle* notepad_apphandle = <CAppHandle*>0
    cdef CProcess* notepad_cprocess = <CProcess*>0

    
    print("     - get_handle_to_notepad     ... ", end="", flush=True)
    notepad_apphandle = get_handle_to_notepad()
    if not notepad_apphandle:
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")


    print("     - create_notepad_cprocess   ... ", end="", flush=True)
    if notepad_apphandle:
        notepad_cprocess = create_notepad_cprocess(notepad_apphandle)
        if not notepad_cprocess:
            print("FAILED")
            error_count += 1
        else:
            print("PASSED")
    else:
        print("FAILED")
        error_count += 1

    if notepad_cprocess:
        CProcess_free(notepad_cprocess)
    if notepad_apphandle:
        CAppHandle_free(notepad_apphandle)
    notepad_process.terminate()
    return error_count