from CythonVirtualMemoryToolkit import process


app = process.Application(b"Step", True)

number: int = app.read_memory_int8(0x01480000)

print(number)
