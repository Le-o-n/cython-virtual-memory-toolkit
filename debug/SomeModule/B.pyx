cimport win_Def

cdef win_Def.BYTE some_byte = 2

def main():
    print(f">> {str(some_byte)}")