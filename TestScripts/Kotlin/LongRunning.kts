println("Starting long running task...")
System.out.flush()

for (i in 1..5) {
    Thread.sleep(1000)
    println("Processing step $i/5")
    System.out.flush()
}

println("Done!")
System.out.flush()
