from CythonVirtualMemoryToolkit import process


app = process.Application(b"Step", True)

#app.read_memory_int8(0x66250a84)
x = app.read_memory_int8(0x0169FDD0)
print(x)
