module either;

version(unittest) {
  import fluent.asserts;
}

///
enum EitherSide {
  Left, Right
}

///
struct Either(Left, Right) {

  private {
    Left left;
    Right right;
    EitherSide side;
  }

  this(Left value) {
    left = value;
    side = EitherSide.Left;
  }

  this(Right value) {
    right = value;
    side = EitherSide.Right;
  }

  bool hasLeft() {
    return side == EitherSide.Left;
  }

  bool hasRight() {
    return side == EitherSide.Right;
  }
}

/// hasLeft is true when the struct is setup with the left type
unittest {
  auto either = Either!(int, bool)(1);

  either.hasLeft.should.equal(true);
}

/// hasRight is false when the struct is setup with the left type
unittest {
  auto either = Either!(int, bool)(1);

  either.hasRight.should.equal(false);
}

/// hasLeft is false when the struct is setup with the right type
unittest {
  auto either = Either!(int, bool)(true);

  either.hasLeft.should.equal(false);
}

/// hasRight is true when the struct is setup with the right type
unittest {
  auto either = Either!(int, bool)(true);

  either.hasRight.should.equal(true);
}