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

bool canCheck(alias Matcher, ParameterType)() {
  static if(!isCallable!Matcher) {
    return false;
  } else static if(Parameters!Matcher.length != 1) {
    return false;
  } else static if(!is(Parameters!Matcher[0] == ParameterType)) {
    return false;
  } else static if(!is(ReturnType!Matcher == bool)) {
    return false;
  } else {
    return true;
  }
}

/// Returns true if the given struct can be use as an Either struct
template isEitherStruct(T) if(hasMember!(T, "isLeft") && hasMember!(T, "isRight")) {
  enum isEitherStruct = true;
}

/// ditto
template isEitherStruct(T) if(!hasMember!(T, "isLeft") || !hasMember!(T, "isRight")) {
  enum isEitherStruct = false;
}

/// Returns true if the function returns void
template hasVoidReturn(Func) {
  static if (is(ReturnType!Func == void)) {
    enum hasVoidReturn = true;
  } else {
    enum hasVoidReturn = false;
  }
}

///
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

  // Type matchers

  This when(Matcher)(Matcher matcher) if(isCallableWith!(Matcher, Left) && hasVoidReturn!Matcher) {
    if(isLeft) {
      matcher(left);
    }

    return this;
  }

  This when(Matcher)(Matcher matcher) if(isCallableWith!(Matcher, Left) && !hasVoidReturn!Matcher) {
    static if(
      !is(ReturnType!Matcher == This) &&
      !is(ReturnType!Matcher == Left) &&
      !is(ReturnType!Matcher == Right)
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

  This when(Matcher)(Matcher matcher) if(isCallableWith!(Matcher, Right) && hasVoidReturn!Matcher) {
    if(isRight) {
      matcher(right);
    }

    return this;
  }

  This when(Matcher)(Matcher matcher) if(isCallableWith!(Matcher, Right) && !hasVoidReturn!Matcher) {
    static if(
      !is(ReturnType!Matcher == This) &&
      !is(ReturnType!Matcher == Left) &&
      !is(ReturnType!Matcher == Right)
    ) {
      static assert(false, "when() returns `" ~ ReturnType!Matcher.stringof ~
        "`. It must return `" ~ Left.stringof ~ "`, `" ~ Right.stringof ~ "` or `Either!(" ~ Left.stringof ~ ", " ~ Right.stringof ~ ")`");
    } else {
      if(isRight) {
        return matcher(right).bind!(Left, Right);
      }

      return this;
    }
  }

  This when(Matcher)(Matcher matcher) if(!isCallableWith!(Matcher, Left) && !isCallableWith!(Matcher, Right)) {
    return this;
  }

  // value matchers

  This when(alias value, Matcher)(Matcher matcher) if(is(typeof(value) == Left) && isCallable!Matcher && Parameters!Matcher.length == 0) {
    if(isLeft && value == left) {
      auto result = matcher();
      return result.bind!This;
    }

    return this;
  }

  This when(alias value, T)(T newValue) if((is(T == Left) || is(T == Right)) && is(typeof(value) == Left)) {
    if(isLeft && value == left) {
      return newValue.bind!This;
    }

    return this;
  }

  This when(alias value, Func)(Func matcher) if(is(typeof(value) == Right) && isCallable!Func && Parameters!Func.length == 0) {
    if(isRight && value == right) {
      auto result = matcher();
      return result.bind!This;
    }

    return this;
  }

  This when(alias value, T)(T newValue) if((is(T == Left) || is(T == Right)) && is(typeof(value) == Right)) {
    if(isRight && value == right) {
      return newValue.bind!This;
    }

    return this;
  }

  // function matchers

  This when(alias check, Matcher)(Matcher matcher) if(canCheck!(check, Right) && isCallable!Matcher && Parameters!Matcher.length == 0) {
    if(isRight && check(right)) {
      return matcher().bind!This;
    }

    return this;
  }

  This when(alias check, T)(T newValue) if((is(T == Right) || is(T == Left)) && canCheck!(check, Right)) {
    if(isRight && check(right)) {
      return newValue.bind!This;
    }

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

/// it calls the 'when' with left value function when the monad isLeft is true
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

/// it calls the 'when' with right value function when the monad isRight is true
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

/// it does not call the 'when' function when the types don't match
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

/// it returns the binded value when the 'when' function returns
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

/// it calls the 'when' function when the value matches the Left
unittest {
  auto either = Either!(int, bool)(1);
  bool message;

  auto result = either
    .when!1 ({
      return true;
    })
    .when((bool value) {
      message = value;
    });

  result.isRight.should.equal(true);
  message.should.equal(true);
}

/// it does not call the 'when' function when the value matches the Left
unittest {
  auto either = Either!(int, bool)(1);
  bool message;

  auto result = either
    .when!11 ({
      return true;
    })
    .when((bool value) {
      message = value;
    });

  result.isLeft.should.equal(true);
  message.should.equal(false);
}

/// it calls the 'when' function when the value matches the Right
unittest {
  auto either = Either!(int, bool)(true);
  int message;

  auto result = either
    .when!true ({
      return 2;
    })
    .when((int value) {
      message = value;
    });

  result.isLeft.should.equal(true);
  message.should.equal(2);
}

/// it does not call the 'when' function when the value matches the Left
unittest {
  auto either = Either!(int, bool)(true);
  bool message;

  auto result = either
    .when!false ({
      return 3;
    })
    .when((bool value) {
      message = value;
    });

  result.isRight.should.equal(true);
  message.should.equal(true);
}

/// it returns the 'when' value when the value matches the Right
unittest {
  auto either = Either!(int, bool)(true);
  int message;

  auto result = either
    .when!true (2)
    .when((int value) {
      message = value;
    });

  result.isLeft.should.equal(true);
  message.should.equal(2);
}

/// it does not return the 'when' value when the value is not matched
unittest {
  auto either = Either!(int, bool)(true);
  bool message;

  auto result = either
    .when!false (3)
    .when((bool value) {
      message = value;
    });

  result.isRight.should.equal(true);
  message.should.equal(true);
}

/// it returns the 'when' value when the value matches the Left
unittest {
  auto either = Either!(int, bool)(1);
  bool message;

  auto result = either
    .when!1 (true)
    .when((bool value) {
      message = value;
    });

  result.isRight.should.equal(true);
  message.should.equal(true);
}

/// it does not return the 'when' value when the value is not matched
unittest {
  auto either = Either!(int, bool)(2);
  bool message;

  auto result = either
    .when!(3) (true)
    .when((bool value) {
      message = value;
    });

  result.isLeft.should.equal(true);
  message.should.equal(false);
}


version(unittest) {
  bool alwaysTrue(bool) {
    return true;
  }

  bool alwaysFalse(bool) {
    return false;
  }
}

/// it calls the 'when' function when the function check returns true for Right value
unittest {
  auto either = Either!(int, bool)(true);
  int message;

  auto result = either
    .when!alwaysTrue ({
      return 2;
    })
    .when((int value) {
      message = value;
    });

  result.isLeft.should.equal(true);
  message.should.equal(2);
}

/// it does not call the 'when' function when the function check returns false for Right value
unittest {
  auto either = Either!(int, bool)(true);
  bool message;

  auto result = either
    .when!alwaysFalse ({
      return 2;
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
Either!(Left, Right) bind(Left, Right, T)(T value) if(!isEitherStruct!Left && !isEitherStruct!Right && !isEitherStruct!T) {
  return Either!(Left, Right)(value);
}

/// ditto
auto bind(E, T)(T value) if(isEitherStruct!E) {
  return E(value);
}

/// ditto
Either!(Left, Right) bind(Left, Right)(Either!(Left, Right) value) if(!isEitherStruct!Left && !isEitherStruct!Right) {
  return value;
}

/// returns a right hand Either when the value is an int
unittest {
  auto result = bind(5);

  result.isLeft.should.equal(false);
  result.isRight.should.equal(true);
}