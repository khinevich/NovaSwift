# NovaSwift

Native macOS integrated development environment (IDE) specifically built for writing and executing Swift and Kotlin scripts with high performance and a modern user interface.

1. Editor pane and output pane.
2. Write script to a file and run it using `/usr/bin/env swift` or `kotlinc -script`.
3. Support for long-running and **interactive** scripts.
4. Live, **unbuffered** output of the script as it executes.
5. Display of errors and execution failures with **enhanced navigation**.
6. Intelligent status bar indicating "Ready", "Running...", or "Awaiting for user input".
7. System notifications when scripts require your attention.
8. Indication of non-zero exit codes.
9. Syntax highlighting for keywords, types, strings, and comments.
10. Clickable error locations to navigate to code across different files.

![NovaSwift Logo](NovaSwift.png)

## Features

NovaSwift provides a streamlined experience for script development on macOS:

*   **Multi-Language Support:** Write and execute **Swift** (`.swift`) and **Kotlin** (`.kts`) scripts seamlessly.
*   **Interactive Scripts:** Support for standard input (`stdin`). A dedicated input field appears automatically when a script is waiting for your input.
*   **System Notifications:** Receive macOS desktop notifications when a script is waiting for input (e.g., `"InputTest.swift requires your attention"`), even if the app is in the background.
*   **Intelligent Status:** The status bar uses heuristics to detect when a script is likely waiting for input (e.g., lines ending in `:` or `?`), updating its state to "Awaiting for the user input".
*   **Unbuffered Real-time Output:** Child processes run with `NSUnbufferedIO` enabled, ensuring that prompts and log messages appear instantly without needing manual `fflush` calls in your code.
*   **Enhanced Error Navigation:** Click on any error in the console (e.g., `main.swift:10:5`) to jump directly to that line. NovaSwift automatically opens the referenced file if it's not already active.
*   **Syntax Highlighting:** Native, performant syntax highlighting for keywords, types, strings, and comments in both supported languages.
*   **File Explorer:** Integrated sidebar to browse your project folder, visualize file structures, and recognize language-specific file types.
*   **Settings & Customization:** Configure your environment with support for Dark/Light mode, adjustable font sizes, and custom paths for Swift and Kotlin executables.

## Keyboard Shortcuts

Boost your productivity with these built-in shortcuts:

| Action | Shortcut | Description |
| :--- | :---: | :--- |
| **Run Script** | `Cmd + R` (⌘R) | Compiles and executes the currently open script. |
| **Save File** | `Cmd + S` (⌘S) | Saves the current changes to the open file. |
| **Increase Font** | `Cmd + +` | Increases the editor font size. |
| **Decrease Font** | `Cmd + -` | Decreases the editor font size. |

## Getting Started

### Prerequisites

*   **Swift:** Pre-installed on macOS.
*   **Kotlin:** To run Kotlin scripts (`.kts`), you must have the Kotlin compiler installed.
    ```bash
    brew install kotlin
    ```

### Notifications

NovaSwift uses system notifications to alert you when a script needs input. You can manage notification permissions directly in the **Settings** window within the app.

---

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

1. `TestScripts/Swift/InputTest.swift`
       * Purpose: Test **Interactive Scripts** and **Notifications**.
       * Features: Uses `readLine()` to wait for input.
       * Use case: Verify the "Awaiting input" status and system notifications.

2. `TestScripts/Swift/Medium.swift`
       * Purpose: Intermediate logic test.
       * Features: Writes to a temporary file, reads it back, and performs JSON encoding using Codable.
       * Use case: Verify the tool handles filesystem permissions and more complex library imports (Foundation).

3. `TestScripts/Swift/Hard.swift`
       * Purpose: Concurrency and UI responsiveness test.
       * Features: Spawns background threads using DispatchQueue, uses sleep() to simulate delay, and prints heartbeat messages from the main thread.
       * Use case: Critical for testing "Live Output" to ensure your UI updates in real-time and doesn't block while waiting for the script to finish.

4. `TestScripts/Swift/ErrorCompile.swift`
       * Purpose: Syntax highlighting and parsing test.
       * Features: Contains a deliberate syntax error (unclosed string).
       * Use case: Verify your "Error Location" feature (e.g., clickable error messages like line 6: error).

5. `TestScripts/Swift/ErrorRuntime.swift`
       * Purpose: Exit code and crash handling test.
       * Features: Compiles successfully but crashes at runtime (Index out of bounds).
       * Use case: Verify your tool correctly identifies a non-zero exit code and displays runtime errors (stderr).

6. `TestScripts/Kotlin/Hello.kts`
   ```kotlin
   println("Hello from Kotlin!")
   val list = listOf(1, 2, 3)
   list.forEach { println("Item: $it") }
   ```
   *   **Use case:** Import this file into NovaSwift to verify Kotlin syntax highlighting and execution (ensure `kotlinc` is installed).

7. `TestScripts/Kotlin/InputTest.kts`
       * Purpose: Kotlin interaction test.
       * Features: Uses `readln()` to wait for input.
       * Use case: Verify Kotlin stdin support and unbuffered output.

8. `TestScripts/Kotlin/FileIO.kts`
       * Purpose: File permissions and I/O test.
       * Features: Writes to and reads from a file in the current working directory.
       * Use case: Verify that the script executes in a writable directory (temp dir).