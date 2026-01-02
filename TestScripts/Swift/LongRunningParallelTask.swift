#!/usr/bin/env swift

import Foundation

print("---" + " Starting Long Running Parallel Task ---")
print("This script simulates a complex job running on multiple threads.")
print("Estimated duration: ~60 seconds. Please wait...")

let workerCount = 5
let iterations = 10
let group = DispatchGroup()
let queue = DispatchQueue(label: "com.novaswift.parallel", attributes: .concurrent)

// Record start time
let startTime = Date()

for i in 1...workerCount {
    group.enter()
    queue.async {
        print(" [Worker \(i)] Started.")
        
        for step in 1...iterations {
            // Simulate heavy work with sleep
            let sleepTime = UInt32.random(in: 4...6) // Sleep 4-6 seconds per step to total ~50-60s
            sleep(1) 
            
            // Print progress safely
            // Note: In a real app, you might want to synchronize printing, but atomic prints usually work okay for demos
            print(" [Worker \(i)] Completed step \(step)/\(iterations) (Progress: \(step * 10)%) ")
            
            // Simulate work variance
            Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.5))
        }
        
        print(" [Worker \(i)] ✅ Finished all tasks.")
        group.leave()
    }
}

// Notify user that main thread is waiting
print("Main thread: Waiting for workers to finish...")

// Wait for all workers
let result = group.wait(timeout: .now() + 70.0)

let duration = Date().timeIntervalSince(startTime)

switch result {
case .success:
    print("\n✅ All workers completed successfully.")
case .timedOut:
    print("\n⚠️ Operation timed out! Some workers may not have finished.")
}

print("Total execution time: \(String(format: "%.2f", duration)) seconds.")
print("---" + " End of Script ---")
