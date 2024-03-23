from CythonVirtualMemoryToolkit import process

while True:
    wind = process.WindowHandle(b"some_window.txt - Notepad")

    print(wind.get_handle())
