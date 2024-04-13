from .windows_types cimport SIZE_T
from .windows_types cimport DWORD


cdef extern from "Windows.h":
    DWORD PROCESS_ALL_ACCESS
    DWORD MEM_COMMIT
    DWORD PAGE_READWRITE
    DWORD PAGE_WRITECOPY
    DWORD PAGE_EXECUTE_READWRITE
    DWORD PAGE_EXECUTE_WRITECOPY
    DWORD PAGE_NOACCESS
    DWORD MEM_DECOMMIT


cdef extern from "tlhelp32.h":
    cdef SIZE_T MAX_MODULES = 1024  # Arbitrarily chosen limit
    cdef SIZE_T MAX_MODULE_NAME32   # = 255
    cdef SIZE_T MAX_PATH            # = 260

    DWORD TH32CS_SNAPMODULE32
    DWORD TH32CS_SNAPMODULE