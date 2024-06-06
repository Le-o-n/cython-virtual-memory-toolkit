from VirtualMemoryToolkit.tests import test_process, test_handles # type: ignore

def main() -> None:

    failed_process_tests: int = test_process.run()
    failed_handles_tests: int = test_handles.run()
    
    if not failed_process_tests:
        print(" ** Passed all Process tests **")
    else:
        print(f" ** Failed {failed_process_tests} Handles tests **")
    
    
    if not failed_handles_tests:
        print(" ** Passed all Handles tests **")
    else:
        print(f" ** Failed {failed_handles_tests} Handles tests **")



if __name__ == "__main__":
    main()