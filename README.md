# Either

This is a DLang implementation for the Either monad.

The Either type represents values with two possibilities: a Left value or a Right value, and never both.

The Either type is sometimes used to represent a value which is either correct or an error;
by convention, the Left constructor is used to hold an error value and the Right constructor
is used to hold a correct value (mnemonic: "right" also means "correct").

## How to use

### Instantiation

You can initialize a struct directly or by using the bind function. All of these instantiations are equivalent:

```d
  auto myEither = Either!(Left, Right)(someValue);
  auto myEither = bind!(Left, Right)(someValue)
```

### Type matching

  Most of the time, the Right type matcher is used for the algorithm and the Left type matcher for error handling.

  ```d
    auto either = Either!(int, bool)(1);

    either
      .when((int value) {
        // ... handle the value when it has the Left type
      })
      .when((bool value) {
        // ... handle the value when it has the Right type
      });
  ```

### Value matching

```d
  auto either = Either!(int, bool)(1);

  auto result = either
    .when!1 ({
      // ... do something when the value has the Left type and is 1
    })
    .when!false {
      // ... do something when the value has the Right type and is false
    })
    .when!true {
      return 2; // when the value is true it is replaced with 2
    })
    .when!true (2); // this is the shortened version of the previous matcher
```


### Function matching

```d

  bool function isOdd(int value) {
    return value % 2 == 1;
  }

  bool function isEven(int value) {
    return value % 2 == 0;
  }

  auto either = Either!(int, bool)(1);

  auto result = either
    .when!isOdd ({
      return true; // set the value to true, when the Left value is an odd number
    })
    .when!isEven ((int a) {
      return a / 2; // divide by two if the value is an even number
    });
```

### Example

This is a function that can safe divide two numbers. It returns an Either struct, where the Left type(the error) is a string and the Right value is a numeric type.

```d
  Either!(string, NumericType) divideBy(U, V, NumericType)(Either!(U, NumericType) numerator, Either!(V, NumericType) denominator) {
    enum NumericType zero = 0;

    return denominator
      .when!(zero) ("Division by zero!")                   // when denominator is zero, return Left value: "Division by zero!"
      .when!(isNaN!NumericType) ("Denominator is NaN.")    // when denominator is NaN, return Left value: "Denominator is NaN."
      .when((NumericType a) =>                             // when denominator has the Right type
        numerator
          .when!(isNaN!NumericType) ("Numerator is NaN.")  // when numerator is NaN, return Left value: "Numerator is NaN."
          .when((NumericType b) => b / a)                  // when numerator has the Right type, return the division
      );
  }
```

The above function can be used like this:

```d
  auto result = 30.bind!(string, int).divideBy(4.bind!(string, int));
```

or you can add a to string method that can help you to print the value:

```d
  string toString(T)(Either!(string, T) result) {
    import std.conv;

    string message;

    result
      .when ((string error) { message = "Error: " ~ error; })
      .when ((T value) { message = value.to!string; });

    return "\t" ~ message ~ "\n";
  }
```

and print the result to the console:

```d
  writeln("30 / 4 =");

  30.bind!(string, int)
    .divideBy(4.bind!(string, int))
    .toString
    .writeln;
```


... for a complete example you can check the source code [here](either/source/examples/safeDivision.d).


## License

[MIT](License)