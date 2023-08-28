import knot

type Namespace = object

block:
  tie Namespace:
    type Foo = ref object
      case a: bool
      of true: x: string
      else: discard
    const bar = "abc"
    proc baz(x: int): string = "int " & $x
    proc baz(x: float): string = "float " & $x
  when true: # Foo is not locally declared due to https://github.com/nim-lang/Nim/issues/22571
    type Foo = Namespace.pick(Foo)
  doAssert Foo(a: true, x: "abc").x == bar
  doAssert baz(123) == "int 123"
  doAssert baz(1.23) == "float 1.23"

  tie Namespace:
    type Generic[T] = ref object
      case a: bool
      of true: x: T
      else: discard
  doAssert Generic[string](a: true, x: "abc").x == bar

doAssert Namespace.pick(Foo)(a: true, x: "abc").x == Namespace.pick(bar)
doAssert Namespace.choice(baz)(123) == "int 123"
doAssert Namespace.choice(baz)(1.23) == "float 1.23"

when false: # can't explicitly instantiate generic type symbol
  doAssert Namespace.pick(Generic)[string](a: true, x: "abc").x == Namespace.pick(bar)
