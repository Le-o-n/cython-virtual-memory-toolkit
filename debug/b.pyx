from windows.windows_types cimport BYTE
from windows.windows_types cimport WORD
from windows.windows_defs cimport PROCESS_ALL_ACCESS

cdef WORD count = 0
def inc():
    global count
    count = count + 1
    return count

def proc_all_access():
    return PROCESS_ALL_ACCESS