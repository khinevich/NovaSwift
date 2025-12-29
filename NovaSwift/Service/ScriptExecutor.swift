//
//  ScriptExecutor.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import Foundation

enum ProcessOutput {
    case stdout(String)
    case exitCode(Int32)
}

@Observable
class ScriptExecutor {
    private var process: Process?
    
    func execute(_ script: String) -> AsyncStream<ProcessOutput> {
        AsyncStream { continuation in
            let tempDirectory = FileManager.default.temporaryDirectory
            let scriptPath = tempDirectory.appending(path: "script.swift")
            
            do {
                try script.write(to: scriptPath, atomically: true, encoding: .utf8)
            } catch {
                continuation.yield(.stdout("Error: Could not write temporary file."))
                continuation.finish()
                return
            }
            self.process = Process()
            process?.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process?.arguments = ["swift", "\(scriptPath.path)"]
            let pipe = Pipe()
            process?.standardOutput = pipe
            process?.standardError = pipe
            
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    continuation.yield(.stdout(output))
                }
            }
            process?.terminationHandler = { p in
                continuation.yield(.exitCode(p.terminationStatus))
                continuation.finish()
            }
            
            do {
                try process?.run()
            } catch {
                continuation.yield(.stdout("Failed to run process: \(error.localizedDescription)"))
                continuation.finish()
            }
        }
    }
    
    func stop() {
        process?.terminate()
    }
}
