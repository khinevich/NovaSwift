// InputTest.kts
// Tests interactive input (stdin) support

print("What is your name? ")
// Flush output to ensure prompt is visible before waiting for input
// Note: In some Kotlin script runners, explicit flushing might differ, but println usually suffices.

val name = readLine()

if (name != null && name.isNotBlank()) {
    println("Hello, $name! Nice to meet you.")
} else {
    println("Hello, stranger!")
}
