cdef extern from "Windows.h":
    ctypedef unsigned long DWORD
    ctypedef unsigned long HANDLE
    ctypedef long* LPARAM
    ctypedef int BOOL

    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId)
    
cdef unsigned long PROCESS_ALL_ACCESS = 0x001FFFFF

def open_process(long process_id) -> long:
    return OpenProcess(<unsigned long>PROCESS_ALL_ACCESS, False, <unsigned long>process_id)
