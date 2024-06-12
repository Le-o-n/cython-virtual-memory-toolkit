from virtual_memory_toolkit.windows.windows_types cimport LPCSTR, BYTE, LPSTR

cpdef int main():
    cdef char[10] temp_string = b"some_text"
    
    cdef LPSTR some_string = <LPSTR>temp_string
    cdef LPCSTR some_const_string = <LPCSTR>some_string

    some_string[0] = ord('b')

    print(some_string.decode('utf-8'))

    print(some_const_string.decode('utf-8'))
    
    cdef BYTE some_byte = 4
    some_byte = some_byte + 10
    print(some_byte)

    return 0
