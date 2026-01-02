#!/usr/bin/env swift

import Foundation

print("--- Starting Runtime Error Script ---")
print("Everything looks fine so far...")

let numbers = [1, 2, 3]
print("Accessing index 10...")

// This will cause a runtime crash (Index out of range)
let crash = numbers[10]

print("This line will never execute.")
