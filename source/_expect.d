module _expect;

version(unittest):

import std.conv;
import std.exception;

struct Expect(T) {
  T testedValue;

  auto to() {
    return this;
  }

  auto equal(U)(U expectedValue) {
    enforce(testedValue == expectedValue, testedValue.to!string ~ " does not equal to " ~ expectedValue.to!string ~ "." );
  }
}

auto expect(T)(T testedValue) {
  return Expect!T(testedValue);
}

alias should = expect;

// it can test a number with itself
unittest {
  expect(1).to.equal(1);
}

// it throws an exception when the values don't equal
unittest {
  try {
    expect(1).to.equal(2);
  } catch(Exception e) {
    assert(e.message == "1 does not equal to 2.");
  }
}