// @dart = 3.7

class Person {
  Person(this.name);

  final String name;
}

augment class Person {
  @override
  String toString() {
    return 'Person(name: $name)';
  }
}

void main() {
  var person =  Person('John Doe');

  print(person);
}
