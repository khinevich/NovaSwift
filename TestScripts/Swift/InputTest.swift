import Foundation

// Helper to flush stdout so the prompt appears immediately
func flushStdout() {
    fflush(stdout)
}

print("What is your name?")
flushStdout()

if let name = readLine() {
    print("Hello, \(name)! Nice to meet you.")
} else {
    print("Hello, stranger!")
}
