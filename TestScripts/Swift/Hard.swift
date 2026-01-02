#!/usr/bin/env swift

import Foundation

print("--- Starting Hard Script (Concurrency & Long Running) ---")
print("This script simulates a long-running task with multiple threads.")
print("Watch the output pane for live updates...")

let group = DispatchGroup()
let queue = DispatchQueue(label: "com.novaswift.worker", attributes: .concurrent)

for i in 1...3 {
    group.enter()
    queue.async {
        let sleepTime = UInt32.random(in: 1...3)
        print(" -> Worker \(i) started. Working for \(sleepTime) seconds...")
        sleep(sleepTime)
        print(" <- Worker \(i) finished.")
        group.leave()
    }
}

// simulate main thread work while waiting
print("Main thread waiting for workers...")
var counter = 0
while group.wait(timeout: .now() + 0.5) == .timedOut {
    counter += 1
    print(" . Main thread heartbeat \(counter) (0.5s)")
    if counter >= 10 {
         print("Timeout warning! Workers are taking too long.")
         break
    }
}

print("All workers finished (or timed out).")
print("--- Finished Hard Script ---")
