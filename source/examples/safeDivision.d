module examples.safeDivision;

import either;
import fluent.asserts;
import std.traits;
import std.math;

bool isNaN(X)(X x) if (!isFloatingPoint!(X)) {
  return false;
}

bool isNaN(X)(X x) if (isFloatingPoint!(X)) {
  return std.math.isNaN(x);
}

///
Either!(string, T) divideBy(T)(T numerator, T denominator) if(!isEitherStruct!T) {
  return numerator
    .bind!(string, T)
    .divideBy(
      denominator.bind!(string, T)
    );
}

///
Either!(string, T) divideBy(T)(Either!(string, T) numerator, T denominator) if(!isEitherStruct!T) {
  return numerator
    .divideBy(
      denominator.bind!(string, T)
    );
}

///
Either!(string, NumericType) divideBy(U, V, NumericType)(Either!(U, NumericType) numerator, Either!(V, NumericType) denominator) {
  enum NumericType zero = 0;

  return denominator
    .when!(zero) ("Division by zero!")
    .when!(isNaN!NumericType) ("Denominator is NaN.")
    .when((NumericType a) =>
      numerator
        .when!(isNaN!NumericType) ("Numerator is NaN.")
        .when((NumericType b) => b / a)
    );
}

/// divideBy with positive integers
unittest {
  auto result = 10.divideBy(5);

  result.isRight.should.equal(true);

  result
    .when((int value) {
      value.should.equal(2);
    });
}

/// divideBy when the denominator is 0
unittest {
  auto result = 10.divideBy(0);

  result.isLeft.should.equal(true);

  result
    .when((string value) {
      value.should.equal("Division by zero!");
    });
}

/// divideBy when the denominator is NaN
unittest {
  double nan;

  auto result = double(10).divideBy(nan);

  result.isLeft.should.equal(true);

  result
    .when((string value) {
      value.should.equal("Denominator is NaN.");
    });
}

/// divideBy when the Numerator is NaN
unittest {
  double nan;

  auto result = double.nan.divideBy(3);

  result.isLeft.should.equal(true);

  result
    .when((string value) {
      value.should.equal("Numerator is NaN.");
    });
}


string toString(T)(Either!(string, T) result) {
  import std.conv;

  string message;

  result
    .when ((string error) { message = "Error: " ~ error; })
    .when ((T value) { message = value.to!string; });

  return "\t" ~ message ~ "\n";
}

version(unittest) {} else
void main() {
  import std.stdio;

  writeln("30 / 4 = ");
  30.divideBy(4)
    .toString
    .writeln;

  writeln("12.2 / 23.2 = ");
  double(12.2)
    .divideBy(22.2)
    .toString
    .writeln;

  writeln("12.2 / 0 = ");
  double(12.2)
    .divideBy(0)
    .toString
    .writeln;

  writeln("12.2 / nan = ");
  double(12.2)
    .divideBy(double.nan)
    .toString
    .writeln;

  writeln("nan / 3 = ");
  double.nan
    .divideBy(double(3))
    .toString
    .writeln;
}