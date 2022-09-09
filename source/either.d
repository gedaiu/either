module either;

import std.traits;

version(unittest) {
  import fluent.asserts;
}

///
enum EitherSide {
  Left, Right
}

///
bool isCallableWith(func, T)() {
  static if(!isCallable!func) {
    return false;
  } else static if(Parameters!func.length != 1) {
    return false;
  } else static if(!is(Parameters!func[0] == T)) {
    return false;
  } else {
    return true;
  }
}

///
template isEither(T) if(hasMember!(T, "isLeft") && hasMember!(T, "isRight")) {
  enum isEither = true;
}

///
template isEither(T) if(!hasMember!(T, "isLeft") || !hasMember!(T, "isRight")) {
  enum isEither = false;
}

struct Any {}

/// The Either type represents values with two possibilities:
///      a value of type Either a b is either Left a or Right b.
///
/// The Either type is sometimes used to represent a value which is either correct or an error;
/// by convention, the Left constructor is used to hold an error value and the Right constructor
/// is used to hold a correct value (mnemonic: "right" also means "correct").
struct Either(Left, Right) if(!is(Left == Right)) {
  alias This = Either!(Left, Right);

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

  bool isLeft() {
    return side == EitherSide.Left;
  }

  bool isRight() {
    return side == EitherSide.Right;
  }

  This when(Func)(Func matcher) if(isCallableWith!(Func, Left) && is(ReturnType!Func == void)) {
    if(isLeft) {
      matcher(left);
    }

    return this;
  }

  This when(Func)(Func matcher) if(isCallableWith!(Func, Left) && !is(ReturnType!Func == void)) {
    static if(
      !is(ReturnType!Func == This) &&
      !is(ReturnType!Func == Left) &&
      !is(ReturnType!Func == Right)
    ) {
      static assert(false, "when() returns `" ~ ReturnType!Func.stringof ~
        "`. It must return `" ~ Left.stringof ~ "`, `" ~ Right.stringof ~ "` or `Either!(" ~ Left.stringof ~ ", " ~ Right.stringof ~ ")`");
    } else {
      if(isLeft) {
        return matcher(left).bind!(Left, Right);
      }

      return this;
    }

  }

  This when(Func)(Func matcher) if(isCallableWith!(Func, Right) && is(ReturnType!Func == void)) {
    if(isRight) {
      matcher(right);
    }

    return this;
  }

  This when(Func)(Func matcher) if(isCallableWith!(Func, Right) && !is(ReturnType!Func == void)) {
    static if(
      !is(ReturnType!Func == This) &&
      !is(ReturnType!Func == Left) &&
      !is(ReturnType!Func == Right)
    ) {
      static assert(false, "when() returns `" ~ ReturnType!Func.stringof ~
        "`. It must return `" ~ Left.stringof ~ "`, `" ~ Right.stringof ~ "` or `Either!(" ~ Left.stringof ~ ", " ~ Right.stringof ~ ")`");
    } else {
      if(isRight) {
        return matcher(right).bind!(Left, Right);
      }

      return this;
    }
  }

  This when(Func)(Func matcher) if(!isCallableWith!(Func, Left) && !isCallableWith!(Func, Right)) {
    return this;
  }
}

/// isLeft is true when the struct is setup with the left type
unittest {
  auto either = Either!(int, bool)(1);

  either.isLeft.should.equal(true);
}

/// isRight is false when the struct is setup with the left type
unittest {
  auto either = Either!(int, bool)(1);

  either.isRight.should.equal(false);
}

/// isLeft is false when the struct is setup with the right type
unittest {
  auto either = Either!(int, bool)(true);

  either.isLeft.should.equal(false);
}

/// isRight is true when the struct is setup with the right type
unittest {
  auto either = Either!(int, bool)(true);

  either.isRight.should.equal(true);
}

/// it calls the where with left value function when the monad isLeft is true
unittest {
  auto either = Either!(int, bool)(1);
  string result = "none";

  either
    .when((int value) {
      result = "left";
    })
    .when((bool value) {
      result = "right";
    });

  result.should.equal("left");
}

/// it calls the where with right value function when the monad isRight is true
unittest {
  auto either = Either!(int, bool)(true);
  string result = "none";

  either
    .when((int value) {
      result = "left";
    })
    .when((bool value) {
      result = "right";
    });

  result.should.equal("right");
}

/// it does not call the where function when the types don't match
unittest {
  auto either = Either!(int, bool)(true);
  string result = "none";

  either
    .when((double value) {
      result = "double";
    })
    .when((string value) {
      result = "string";
    });

  result.should.equal("none");
}

/// it returns the binded value when the where function returns
unittest {
  auto either = Either!(int, bool)(1);
  bool message;

  auto result = either
    .when((int value) {
      return true;
    })
    .when((bool value) {
      message = value;
    });

  result.isRight.should.equal(true);
  message.should.equal(true);
}

/// Wraps a value as an Either monad
Either!(Any, T) bind(T)(T value) {
  return Either!(Any, T)(value);
}

/// ditto
Either!(Left, Right) bind(Left, Right, T)(T value) if(!isEither!T){
  return Either!(Left, Right)(value);
}

/// ditto
Either!(Left, Right) bind(Left, Right)(Either!(Left, Right) value) {
  return value;
}

/// returns a right hand Either when the value is an int
unittest {
  auto result = bind(5);

  result.isLeft.should.equal(false);
  result.isRight.should.equal(true);
}