import knot

type Stringable = concept
  proc toString(x: Self): string

block:
  proc toString(a: int): string {.tie: Stringable.} =
    "int " & $a

block:
  proc toString(a: float): string =
    "float " & $a
  
  tie Stringable, toString

doAssert Stringable.choice(toString)(1) == "int 1"
doAssert Stringable.choice(toString)(1.0) == "float 1.0"
doAssert not compiles(Stringable.choice(toString)(true))

block:
  tie Stringable:
    proc toString(a: bool): string =
      "bool " & $a

doAssert Stringable.choice(toString)(true) == "bool true"
