# NovaSwift

Native macOS integrated development environment (IDE) specifically built for writing and executing Swift and Kotlin scripts with high performance and a modern user interface.

![NovaSwift Logo](NovaSwift.png)

## Getting Started

### Prerequisites

*   **Swift:** Pre-installed on macOS.
*   **Kotlin:** To run Kotlin scripts (`.kts`), you must have the Kotlin compiler installed.
    ```bash
    brew install kotlin
    ```

### Running the Application

You can run NovaSwift either using Xcode (recommended for development) or directly from the terminal.

**Option 1: Using Xcode**
1. Open the project file `NovaSwift.xcodeproj`.
2. Ensure the `NovaSwift` scheme is selected in the top toolbar.
3. Select your Mac as the destination.
4. Press **Command + R** (⌘R) or click the **Run** button (Play icon) in the toolbar.

**Option 2: Using Terminal**
To build and run the application from the command line:

1. Build the application:
   ```bash
   xcodebuild -scheme NovaSwift -destination 'platform=macOS' build
   ```
2. Once built, you can open the application bundle (assuming Debug build):
   ```bash
   open $(xcodebuild -scheme NovaSwift -destination 'platform=macOS' -showBuildSettings | grep -m 1 "TARGET_BUILD_DIR" | cut -d "=" -f 2 | xargs)/NovaSwift.app
   ```

---

### Running Tests

NovaSwift includes a suite of unit tests for its core services (`ScriptExecutor`, `ProjectManager`) and models.

**Option 1: From Xcode**
1. Open `NovaSwift.xcodeproj`.
2. Press **Command + U** (⌘U) to build and run all tests.
3. Alternatively, open the **Test Navigator** (Command + 6), find `NovaSwiftTests`, and click the small play button next to individual tests or suites.

**Option 2: From Terminal**
You can execute the full test suite using `xcodebuild`:

```bash
xcodebuild test -scheme NovaSwift -destination 'platform=macOS'
```

This command will compile the project and run all unit tests, reporting pass/fail status directly in the terminal output.

---

## Test Scripts

The repository includes several sample scripts in `TestScripts/` to verify IDE functionality manually:

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

6. **(New) Kotlin Test:** Create a file named `hello.kts`:
   ```kotlin
   println("Hello from Kotlin!")
   val list = listOf(1, 2, 3)
   list.forEach { println("Item: $it") }
   ```
   *   **Use case:** Import this file into NovaSwift to verify Kotlin syntax highlighting and execution (ensure `kotlinc` is installed).
