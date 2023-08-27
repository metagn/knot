import knot

type ExtensibleEnum = distinct uint8

template currentCount: untyped =
  len(ExtensibleEnum.unravel(values, []))

const A = block:
  const A = ExtensibleEnum(currentCount())
  ExtensibleEnum.tie values, A
  A

const B = block:
  const B = ExtensibleEnum(currentCount())
  ExtensibleEnum.tie values, B
  B

doAssert A.uint8 != B.uint8
doAssert ExtensibleEnum.unravel(values, {}) == {A, B}

const C = block:
  const C = ExtensibleEnum(currentCount())
  ExtensibleEnum.tie values, C
  C

doAssert A.uint8 != C.uint8
doAssert B.uint8 != C.uint8
doAssert ExtensibleEnum.unravel(values, {}) == {A, B, C}
