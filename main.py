
from VirtualMemoryToolkit import process

"""
from VirtualMemoryToolkit.process import AppHandle  # type: ignore
from VirtualMemoryToolkit.errors.handle_error import UnableToAcquireHandle


app: AppHandle | None = None
while not app:
    try:
        app = AppHandle.from_window_name(b"Steam")
    except UnableToAcquireHandle:
        print("Unable to find window!")
        app = None
        time.sleep(1)
    except Exception as e:
        print(f"Unknown exception! {str(e)}")
        exit(-1)

print(app)
"""
