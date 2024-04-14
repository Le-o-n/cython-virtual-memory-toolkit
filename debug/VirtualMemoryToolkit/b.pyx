from windows.windows_defs cimport privileged_memory_read
from windows.windows_defs cimport PROCESS_ALL_ACCESS
from windows.windows_types cimport WORD, HANDLE, LPCVOID, LPVOID
from libc.stdlib cimport malloc, free, realloc


def run():
    cdef LPVOID buffer = malloc(<size_t>5)
    privileged_memory_read(<HANDLE>0, <LPCVOID>0, buffer, 5)

    free(buffer)