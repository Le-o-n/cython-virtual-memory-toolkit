from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
import subprocess
import time

def create_notepad_instance():
    """
    Creates a new instance of Notepad by opening it using the specified path.
    """
    notepad_path = "C:\\Windows\\System32\\notepad.exe"
    return subprocess.Popen([notepad_path])

cdef int get_handle_to_notepad():
    """
    Creates a Notepad instance and retrieves its handle.

    Returns:
        int: 0 on success, 1 on failure.
    """

    cdef const char* notepad_title = b"Notepad"
    
    cdef CAppHandle* app_handle = CAppHandle_from_title_substring(notepad_title)

    cdef return_code = not app_handle

    if app_handle:
        CAppHandle_free(app_handle)
    return return_code

cpdef int run():
    """
    Runs the handle tests and prints the results.

    Returns:
        int: The number of errors encountered during the tests.
    """
    print("\n Running Handles Tests ")
    
    notepad_process = create_notepad_instance()
    
    # Add a slight delay to ensure Notepad has time to open
    time.sleep(1)

    cdef int error_count = 0

    
    
    print("     - get_handle_to_notepad  ... ", end="", flush=True)
    
    if get_handle_to_notepad():
        print("FAILED")
        error_count += 1
    else:
        print("PASSED")

    notepad_process.terminate()
    return error_count
