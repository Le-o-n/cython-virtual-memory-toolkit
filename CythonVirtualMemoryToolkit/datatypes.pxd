
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdint cimport int8_t, int16_t, int32_t, int64_t
from libcpp.memory cimport unique_ptr
from process cimport ProcessHandle
from addressing cimport VirtualAddress
cimport cython


cdef class VirtualMemory:
    cdef ProcessHandle process_handle  
    cdef VirtualAddress virtual_address

    cdef void set_value(self, uint8_t[:] value) except +
    cdef uint8_t[:] read_value(self) except +
    cdef void set_address(self, uint32_t address) except +
    cdef uint32_t get_address(self) except +
