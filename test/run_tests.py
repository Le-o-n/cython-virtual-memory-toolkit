import test_process, test_handles, test_memory # type: ignore

def main() -> None:
    
    failed_handles_tests: int = test_handles.run()
    failed_process_tests: int = test_process.run()
    failed_memory_tests: int = test_memory.run()
    
    print("\n")
    
    if not failed_handles_tests:
        print(" ** Passed all Handles tests **")
    else:
        print(f" ** Failed {failed_handles_tests} Handles tests **")

    if not failed_process_tests:
        print(" ** Passed all Process tests **")
    else:
        print(f" ** Failed {failed_process_tests} Handles tests **")
    
    if not failed_memory_tests:
        print(" ** Passed all Memory tests **")
    else:
        print(f" ** Failed {failed_memory_tests} Memory tests **")
        
    input("Press ENTER to continue...")    
if __name__ == "__main__":
    main()