import macros, macrocache

const typeIdCounter = CacheCounter"knot.typeids"

type TypeId* = distinct int

macro newId(): TypeId =
  inc typeIdCounter
  result = newCall(bindSym"TypeId", newLit(typeIdCounter.value))

proc getTypeId*(T: type): TypeId =
  const id = newId()
    # only generated when proc is compiled, i.e. instantiated according to `T`
  id

proc associationCache(t: TypeId, name: string): CacheSeq =
  CacheSeq("knot.associations." & $t.int & ":" & name)

proc associate*(t: TypeId, name: string, node: NimNode) =
  associationCache(t, name).add(node)

iterator associations*(t: TypeId, name: string): NimNode =
  for n in associationCache(t, name):
    yield n
