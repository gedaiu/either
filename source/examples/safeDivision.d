module examples.safeDivision;

import either;
import fluent.asserts;

Either!(string, T) divideBy(T)(T numerator, T denominator) if(!isEither!T) {
  return numerator
    .bind!(string, T)
    .divideBy(
      denominator.bind!(string, T)
    );
}

Either!(string, T) divideBy(U, V, T)(Either!(U, T) numerator, Either!(V, T) denominator) {
  return denominator
    .when((T a) {
      if(a == 0) {
        return Either!(string, T)("Division by zero!");
      }

      return numerator.when((T b) {
        return b / a;
      });
    });
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
    .when((int value) {
      value.should.equal(2);
    });
}