import knot

type Foo = object

const bar {.tie: Foo.} = 123

doAssert Foo.pick(bar) == 123

tie Foo:
  proc baz(x: int): string = "int " & $x
  proc baz(x: float): string = "float " & $x

doAssert Foo.choice(baz)(123) == "int 123"
doAssert Foo.choice(baz)(1.23) == "float 1.23"

Foo.tie collection, 1
Foo.tie collection, 2
Foo.tie collection, 3

doAssert Foo.unravel(collection, []) == [1, 2, 3]
doAssert Foo.unravel(collection, {}) == {1, 2, 3}
