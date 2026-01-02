class Person(val name: String, var age: Int) {
    fun introduce() {
        println("Hi, I am $name and I am $age years old.")
    }
}

val alice = Person("Alice", 30)
alice.introduce()

// Birthday
alice.age += 1
println("${alice.name} is now ${alice.age}")
