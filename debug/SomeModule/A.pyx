cimport win_Def

cdef win_Def.BYTE some_byte = 1

def main():
    print(f">> {str(some_byte)}")