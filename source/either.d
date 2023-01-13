module either;

import std.traits;
import std.conv;

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

///
auto checkEither(alias check, This: Either!(Left, Right), Left, Right)(This either) {
  static if(canCheck!(check, Left)) {
    if(either.isLeft && check(either.left)) {
      return true;
    }
  }

  static if(canCheck!(check, Right)) {
    if(either.isRight && check(either.right)) {
      return true;
    }
  }

  return false;
}

///
auto callWith(MapFunction, This: Either!(Left, Right), Left, Right)(This either, MapFunction mapFunction) if(isCallable!MapFunction) {
  static if(Parameters!MapFunction.length == 0) {
    return mapFunction();
  }

  static if(Parameters!MapFunction.length == 1 && isCallableWith!(MapFunction, Left)) {
    if(either.isLeft) {
      return mapFunction(either.left);
    } else {
      assert(0, "Got a right value. The mapFunction can't be called.");
    }
  }

  static if(Parameters!MapFunction.length == 1 && isCallableWith!(MapFunction, Right)) {
    if(either.isRight) {
      return mapFunction(either.right);
    } else {
      assert(0, "Got a left value. The mapFunction can't be called.");
    }
  }

  static if(Parameters!MapFunction.length > 1) {
    static assert(false, "The map function must get none or 1 argument.");
  }
}

///
auto callIfCan(MapFunction, This: Either!(Left, Right), Left, Right)(This either, MapFunction mapFunction) if(isCallable!MapFunction) {
  This result = either;

  static if(Parameters!MapFunction.length == 0) {
    static if(hasVoidReturn!MapFunction) {
      mapFunction();
    } else {
      result = mapFunction().bind!This;
    }
  }

  static if(Parameters!MapFunction.length == 1 && isCallableWith!(MapFunction, Left)) {
    if(either.isLeft) {
      static if(hasVoidReturn!MapFunction) {
        mapFunction(either.left);
      } else {
        result = mapFunction(either.left).bind!This;
      }
    }
  }

  static if(Parameters!MapFunction.length == 1 && isCallableWith!(MapFunction, Right)) {
    if(either.isRight) {
      static if(hasVoidReturn!MapFunction) {
        mapFunction(either.right);
      } else {
        result = mapFunction(either.right).bind!This;
      }
    }
  }

  static if(Parameters!MapFunction.length > 1) {
    static assert(false, "The map function must get none or 1 argument.");
  }

  return result;
}

/// Returns true if the given struct can be use as an Either struct
template isEitherStruct(T) if(isAggregateType!T && hasMember!(T, "left") && hasMember!(T, "right")) {
  enum isEitherStruct = true;
}

/// ditto
template isEitherStruct(T) if(isBuiltinType!T || !isAggregateType!(T) || !hasMember!(T, "left") || !hasMember!(T, "right")) {
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

/// Check if the matcher returns any of the provided return types
bool returnsAnyOf(Matcher, ReturnTypes...)() {
  static if(ReturnTypes.length == 0) {
    return false;
  } else static if(is(ReturnType!Matcher == ReturnTypes[0])) {
    return true;
  } else {
    return returnsAnyOf!(Matcher, ReturnTypes[1..$]);
  }
}

///
template EitherTypeOf(T, Left, Right) {
  static if(isEitherStruct!T) {
    alias EitherTypeOf = T;
  } else static if(isCallable!T) {
    alias EitherTypeOf = EitherTypeOf!(ReturnType!T, Left, Right);
  } else static if(is(T == Left)) {
    alias EitherTypeOf = Either!(T, Any);
  } else {
    alias EitherTypeOf = Either!(Any, T);
  }
}

template PickDefinedType(A, B) {
  static if(is(A == B) || is(B == Any)) {
    alias PickDefinedType = A;
  } else static if(is(A == Any)) {
    alias PickDefinedType = B;
  } else {
    static assert(false, A.stringof ~ " is not compatible with " ~ B.stringof);
  }
}

///
template NewLeft(This: Either!(Left, Right), That, Left, Right) {
  alias EitherThisLeft = Left;
  alias EitherThatLeft = typeof(EitherTypeOf!(That, Left, Right).left);

  alias NewLeft = PickDefinedType!(EitherThisLeft, EitherThatLeft);
}

///
template NewRight(This: Either!(Left, Right), That, Left, Right) {
  alias EitherThisRight = Right;
  alias EitherThatRight = typeof(EitherTypeOf!(That, Left, Right).right);

  alias NewRight = PickDefinedType!(EitherThisRight, EitherThatRight);
}

///
private auto resolve(T)(T newValue) {
  static if(isCallable!newValue) {
    return newValue();
  } else {
    return newValue;
  }
}

///
struct Any { }

/// The Either type represents values with two possibilities:
///      a value of type Either a b is either Left a or Right b.
///
/// The Either type is sometimes used to represent a value which is either correct or an error;
/// by convention, the Left constructor is used to hold an error value and the Right constructor
/// is used to hold a correct value (mnemonic: "right" also means "correct").
struct Either(Left, Right) if(!is(Left == Right)) {
  /// The type of this Either struct
  alias This = Either!(Left, Right);

  private {
    Left left;
    Right right;
    EitherSide side;
  }

  /// Initialise the struct with the Left type
  this(Left value) {
    left = value;
    side = EitherSide.Left;
  }

  /// Initialise the struct with the Right type
  this(Right value) {
    right = value;
    side = EitherSide.Right;
  }
}

/// returns true when the Left type is stored
bool isLeft(T : Either!(Left, Right), Left, Right)(T either) {
  return either.side == EitherSide.Left;
}

/// isLeft is true when the struct is setup with the left type
unittest {
  auto either = Either!(int, bool)(1);

  either.isLeft.should.equal(true);
}

/// isLeft is false when the struct is setup with the right type
unittest {
  auto either = Either!(int, bool)(true);

  either.isLeft.should.equal(false);
}

/// returns true when the Right type is stored
bool isRight(T : Either!(Left, Right), Left, Right)(T either) {
  return either.side == EitherSide.Right;
}

/// isRight is false when the struct is setup with the left type
unittest {
  auto either = Either!(int, bool)(1);

  either.isRight.should.equal(false);
}

/// isRight is true when the struct is setup with the right type
unittest {
  auto either = Either!(int, bool)(true);

  either.isRight.should.equal(true);
}

version(unittest) {
  alias TestEither = Either!(int, Exception);
}

version(unittest) {
  bool alwaysTrue(bool) {
    return true;
  }

  bool alwaysTrueInt(int) {
    return true;
  }

  bool alwaysFalse(bool) {
    return false;
  }

  bool alwaysFalseInt(int) {
    return false;
  }
}

/// Wraps a value as an Either monad
Either!(Any, T) bind(T)(T value) if(!isEitherStruct!T) {
  return Either!(Any, T)(value);
}

/// ditto
Either!(Left, Right) bind(Left, Right, T)(T value) if(!isEitherStruct!Left && !isEitherStruct!Right && !isEitherStruct!T) {
  return Either!(Left, Right)(value);
}

/// ditto
auto bind(E, T)(T value) if(isEitherStruct!E && !isEitherStruct!T) {
  return E(value);
}

/// ditto
auto bind(T)(T value) if(isEitherStruct!T) {
  return value;
}

/// ditto
void bind(T)() if(isEitherStruct!T) {
  static assert(false, "You can't bind void.");
}

/// ditto
Either!(PickDefinedType!(L, Left), PickDefinedType!(R, Right))
bind(Left, Right, This: Either!(L, R), L, R)(This value)
if(!isEitherStruct!Left && !isEitherStruct!Right && isEitherStruct!This) {
  alias NewL = PickDefinedType!(L, Left);
  alias NewR = PickDefinedType!(R, Right);

  alias LocalEither = Either!(NewL, NewR);

  static if(!is(NewL == Any) && !is(L == Any)) {
    if(value.isLeft) {
      return LocalEither(value.left);
    }
  }

  static if(!is(NewR == Any) && !is(R == Any)) {
    if(value.isRight) {
      return LocalEither(value.right);
    }
  }

  assert(false, "Can't bind value `" ~ value.to!string ~ "` of type `" ~ This.stringof ~ "` to `" ~ LocalEither.stringof ~ "` .");
}

/// returns a right hand Either when the value is an int
unittest {
  auto result = bind(5);

  result.isLeft.should.equal(false);
  result.isRight.should.equal(true);
}

// Type matchers

/// Match Left or Right values using types
This when(Matcher, This: Either!(Left, Right), Left, Right)(This either, Matcher matcher) if(isCallable!Matcher) {
  return either.callIfCan(matcher);
}

/// 'when' is called with the left value function when the monad isLeft is true
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


// Value matchers

/// Match Left or Right values by value examples
auto when(alias value, T, This: Either!(Left, Right), Left, Right)(This either, T newValue) if(!isCallable!value) {
  auto result = newValue.resolve;
  alias ResultType = typeof(result);

  alias NewL = NewLeft!(This, ResultType);
  alias NewR = NewRight!(This, ResultType);
  alias ValueType = typeof(value);

  static if(is(ValueType == Right)) {
    if(either.isRight && value == either.right) {
      return result.bind!(NewL, NewR);
    }

    return either.right.bind!(NewL, NewR);
  }

  static if(is(ValueType == Left)) {
    if(either.isLeft && value == either.left) {
      return result.bind!(NewL, NewR);
    }

    return either.left.bind!(NewL, NewR);
  }
}

/// it is called when the Either value matches the when!Left value
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

/// it is not called when the value matches the Left
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

/// it is called when the value matches the Right
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
  auto either = Either!(int, bool)(2);
  bool message;

  auto result = either
    .when!3 (true)
    .when((bool value) {
      message = value;
    });

  result.isLeft.should.equal(true);
  message.should.equal(false);
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

/// it returns the new Either type
unittest {
  auto either = 5.bind;

  expect(typeof(either).stringof).to.equal("Either!(Any, int)");

  auto result = either.when!(5) ("The value is 5!".bind!(string, int));

  expect(typeof(result).stringof).to.equal("Either!(string, int)");
  expect(result.left).to.equal("The value is 5!");
}

/// returning a left value with any
unittest {
  auto result = 0.bind.when!(0) ("got zero!".bindLeft);

  result.isLeft.should.equal(true);
  result.left.should.equal("got zero!");
}

/// Match Left or Right values using a check function
Either!(NewLeft!(This, T), NewRight!(This, T)) when(alias check, T, This: Either!(Left, Right), Left, Right)(This either, T result) if(isCallable!check) {
  alias NewL = NewLeft!(This, T);
  alias NewR = NewRight!(This, T);

  if(either.checkEither!(check)) {
    static if(isCallable!result) {
      return either.callWith(result).bind!(NewL, NewR);
    } else {
      return result.bind!(NewL, NewR);
    }
  }

  return either.bind!(NewL, NewR);
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

/// it calls the 'when' with the value function when the function check returns true for Right value
unittest {
  auto either = Either!(int, bool)(true);
  int message;

  auto result = either
    .when!alwaysTrue ((bool value) {
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

/// it calls the 'when' function when the function check returns true for Left value
unittest {
  auto either = Either!(int, bool)(8);
  int message;

  auto result = either
    .when!alwaysTrueInt ({
      return 2;
    })
    .when((int value) {
      message = value;
    });

  result.isLeft.should.equal(true);
  message.should.equal(2);
}

///
auto bindLeft(T)(T value) {
  return Either!(T, Any)(value);
}