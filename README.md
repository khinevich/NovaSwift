# NovaSwift

Native macOS integrated development environment (IDE) specifically built for writing and executing Swift scripts with high performance and a modern user interface.

![NovaSwift Logo](NovaSwift.png)


1. `test_script/easy.swift`
       * Purpose: Basic integration test.
       * Features: Simple printing, basic arithmetic, and date display.
       * Use case: Verify the tool can run swift and capture stdout.

2. `test_script/medium.swift`
       * Purpose: Intermediate logic test.
       * Features: Writes to a temporary file, reads it back, and performs JSON encoding using Codable.
       * Use case: Verify the tool handles filesystem permissions and more complex library imports (Foundation).

3. `test_script/hard.swift`
       * Purpose: Concurrency and UI responsiveness test.
       * Features: Spawns background threads using DispatchQueue, uses sleep() to simulate delay, and prints heartbeat messages from the main thread.
       * Use case: Critical for testing "Live Output" to ensure your UI updates in real-time and doesn't block while waiting for the script to finish.

4. `test_script/error_compile.swift`
       * Purpose: Syntax highlighting and parsing test.
       * Features: Contains a deliberate syntax error (unclosed string).
       * Use case: Verify your "Error Location" feature (e.g., clickable error messages like line 6: error).

5. `test_script/error_runtime.swift`
       * Purpose: Exit code and crash handling test.
       * Features: Compiles successfully but crashes at runtime (Index out of bounds).
       * Use case: Verify your tool correctly identifies a non-zero exit code and displays runtime errors (stderr).


swift test_script/easy.swift to see the expected output.
