from CythonVirtualMemoryToolkit import process


app = process.ApplicationHandle(b"Step", True)
x = app.read_memory_bytes(0x000ED498, 2)  # Read 1 byte from memory
bytes_as_ints = list(x)  # Convert each byte in the bytes object to an int
print(bytes_as_ints)

app.write_memory_bytes(0x000ED498, bytes([69,69]))

x = app.read_memory_bytes(0x000ED498, 2)  # Read 1 byte from memory
bytes_as_ints = list(x)  # Convert each byte in the bytes object to an int
print(bytes_as_ints)

