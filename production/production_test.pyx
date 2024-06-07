from VirtualMemoryToolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free


cpdef int run():
    
    cdef CAppHandle* notepad_handle = CAppHandle_from_title_substring(<const char*>"Notepad")

    if not notepad_handle:
        print("No handle :(")
    else:
        print("" + str(notepad_handle[0].pid))

    return 0