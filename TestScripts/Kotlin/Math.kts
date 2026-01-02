fun add(a: Int, b: Int): Int {
    return a + b
}

val result = add(10, 5)
println("10 + 5 = $result")

val numbers = listOf(1, 2, 3, 4, 5)
val doubled = numbers.map { it * 2 }
println("Doubled: $doubled")
