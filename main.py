from CythonVirtualMemoryToolkit import process


app = process.Application(b"Step", True)

#app.read_memory_int8(0x66250a84)
x = app.read_memory_int8(0x05D70000)
print(x)
