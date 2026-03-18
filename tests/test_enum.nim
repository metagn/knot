import knot

template currentCount(T: type): untyped =
  T.tieCount(values)

template define(T: type, name) =
  const `name` = T(currentCount(T))
  T.tie values, `name`
  T.tie valueNames, astToStr(name)

type ExtensibleEnum = distinct uint8

ExtensibleEnum.define A
ExtensibleEnum.define B

doAssert A.uint8 != B.uint8
doAssert ExtensibleEnum.unravel(values, {}) == {A, B}

ExtensibleEnum.define C

doAssert A.uint8 != C.uint8
doAssert B.uint8 != C.uint8
doAssert ExtensibleEnum.unravel(values, {}) == {A, B, C}

proc foo(s: var string, a: ExtensibleEnum) =
  # has to be defined after the values, otherwise generics can be used to delay the compilation
  ExtensibleEnum.unravelCase(values, a) do (val):
    s.add ExtensibleEnum.unravel(valueNames, [])[val.uint8]

var x = B
var msg = ""
foo(msg, x)
doAssert msg == "B"
ExtensibleEnum.unravel(values) do (val):
  msg.foo(val)
doAssert msg == "BABC"
