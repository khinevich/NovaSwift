import java.io.File

val filename = "temp_kotlin_test.txt"
val content = "This file was written by a Kotlin script running in NovaSwift."

println("Writing to $filename...")
File(filename).writeText(content)

println("Reading back...")
val readBack = File(filename).readText()
println("Content: $readBack")

// Cleanup
File(filename).delete()
println("File deleted.")
