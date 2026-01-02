for (i in 1..20) {
    when {
        i % 15 == 0 -> println("FizzBuzz")
        i % 3 == 0 -> println("Fizz")
        i % 5 == 0 -> println("Buzz")
        else -> println(i)
    }
}
