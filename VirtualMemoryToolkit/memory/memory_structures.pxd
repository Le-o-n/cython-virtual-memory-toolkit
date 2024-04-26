
# cdef struct CModule:
#   char* name
#    void* base_address
#    size_t size

#cdef inline CModule* CModule_init(char* name, void* base_address, size_t size):


# struct CVirtualAddress:
#   CAppHandle *app_handle
#   unsigned long long address

#cdef inline CVirtualAddress* CVirtualAddress_init(CAppHandle* app_handle, unsigned long long address):
#cdef inline CVirtualAddress* CVirtualAddress_from_aob(CAppHandle* app_handle, unsigned byte* array_of_bytes, unsigned long long length):
#cdef inline CVirtualAddress* CVirtualAddress_from_static(CAppHandle* app_handle, CModule* module, unsigned long long offset):


#struct CVirtualFloat32:
#    CVirtualAddress* address

#cdef inline CVirtualFloat32* CVirtualFloat32_init(CVirtualAddress* virtual_address):
#cdef inline float32 CVirtualFloat32_read(CVirtualFloat* virtual_float32):
#cdef inline float32 CVirtualFloat32_write(CVirtualFloat* virtual_float32, float32 write_float32):


