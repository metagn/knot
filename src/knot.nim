import knot/internals, macros

macro tieImpl(t: static TypeId, name: static string, value: typed) =
  associate(t, name, value)

macro tie*(T: type, name: untyped, value: typed) =
  ## Tie `value`  to `T` under the name `name`.
  var name = name
  if name.kind in {nnkOpenSymChoice, nnkClosedSymChoice}:
    name = name[0]
  expectKind name, {nnkIdent, nnkSym, nnkStrLit..nnkTripleStrLit}
  result = newCall(bindSym"tieImpl",
    newCall(bindSym"getTypeId", T),
    newLit(name.strVal),
    value)

macro tieRoutine(T: type, routine: typed) =
  let name = if routine[0].kind == nnkPostfix: routine[0][1] else: routine[0]
  expectKind name, nnkSym
  result = newStmtList(routine, newCall(bindSym"tie", T, name, name))

type TypeSectionGen = enum Statement, TypeSection, TypeDef

macro tieTypeSection(T: type, ts: typed, gen: static TypeSectionGen) =
  expectKind ts, nnkTypeSection
  var stmts = newNimNode(if gen == Statement: nnkStmtList else: nnkStmtListType)
  if gen != TypeSection:
    stmts.add(ts)
  for a in ts:
    var name = a[0]
    if name.kind == nnkPragmaExpr: name = name[0]
    if name.kind == nnkPostfix: name = name[1]
    expectKind name, nnkSym
    stmts.add(newCall(bindSym"tie", T, name, name))
  case gen
  of Statement:
    # (type ...; tie ...)
    result = stmts
  of TypeSection:
    # type
    #   ...
    #   _ = (tie ...; void)
    stmts.add(bindSym"void")
    result = ts
    result.add(newTree(nnkTypeDef, ident"_", newEmptyNode(), stmts))
  of TypeDef:
    # _ = (type ...; tie ...; void)
    stmts.add(bindSym"void")
    result = newTree(nnkTypeDef, ident"_", newEmptyNode(), stmts)

macro tieVarSection(T: type, sec: typed) =
  result = newStmtList(sec)
  for d in sec:
    for i in 0..<d.len - 2:
      var name = d[i]
      if name.kind == nnkPragmaExpr: name = name[0]
      if name.kind == nnkPostfix: name = name[1]
      expectKind name, nnkSym
      result.add(newCall(bindSym"tie", T, name, name))

macro tie*(T: type, value: untyped) =
  ## Tie `value` to `T`.
  ## 
  ## If `value` is an identifier or symbol or symbol choice,
  ## it is tied under its own name.
  ## 
  ## If `value` is a routine, type, constant or variable declaration,
  ## the declared symbol is tied under its name.
  ## 
  ## If `value` is a statement list, it applies the above rules to
  ## each statement.
  case value.kind
  of nnkStmtList:
    result = newStmtList()
    for a in value:
      result.add(newCall(bindSym"tie", T, a))
  of RoutineNodes:
    result = newCall(bindSym"tieRoutine", T, value)
  of nnkTypeSection:
    result = newCall(bindSym"tieTypeSection", T, value, bindSym"Statement")
  of nnkTypeDef:
    result = newCall(bindSym"tieTypeSection", T, value,
      when (NimMajor, NimMinor) >= (2, 0):
        bindSym"TypeSection"
      else:
        bindSym"TypeDef")
  of nnkVarSection, nnkLetSection, nnkConstSection:
    result = newCall(bindSym"tieVarSection", T, value)
  of nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice, nnkStrLit..nnkTripleStrLit:
    result = newCall(bindSym"tie", T, value, value)
  else:
    error "unknown node kind for tie " & $value.kind, value

macro pickImpl(T: type, t: static TypeId, name: static string): untyped =
  # T is only for error info
  var done = false
  for n in associations(t, name):
    if done:
      error "more than one node to pick tied to " & repr(T) & " under " & name, T
    else:
      result = n
      done = true

macro pick*(T: type, name: untyped): untyped =
  ## Picks a single node tied to `T` under `name`.
  var name = name
  if name.kind in {nnkOpenSymChoice, nnkClosedSymChoice}:
    name = name[0]
  expectKind name, {nnkIdent, nnkSym, nnkStrLit..nnkTripleStrLit}
  result = newCall(bindSym"pickImpl",
    T,
    newCall(bindSym"getTypeId", T),
    newLit(name.strVal))

macro choiceImpl(T: type, t: static TypeId, name: static string): untyped =
  # T is only for error info
  result = newNimNode(nnkClosedSymChoice, T)
  for n in associations(t, name):
    case n.kind
    of nnkSym: result.add(n)
    of nnkClosedSymChoice, nnkOpenSymChoice:
      for s in n: result.add(s)
    else: error "non-symbol node kind " & $n.kind & " for choice of " & name & " in " & repr(T), T

macro choice*(T: type, name: untyped): untyped =
  ## Gathers the nodes tied to `T` under `name` as a symbol choice.
  var name = name
  if name.kind in {nnkOpenSymChoice, nnkClosedSymChoice}:
    name = name[0]
  expectKind name, {nnkIdent, nnkSym, nnkStrLit..nnkTripleStrLit}
  result = newCall(bindSym"choiceImpl",
    T,
    newCall(bindSym"getTypeId", T),
    newLit(name.strVal))

macro unravelImpl(t: static TypeId, name: static string, node: untyped): untyped =
  result =
    if node.kind in nnkCallKinds + {nnkBracket, nnkPar, nnkTupleConstr, nnkCurly}:
      copy(node)
    else:
      newCall(node)
  result.copyLineInfo(node)
  for n in associations(t, name):
    result.add(n)

macro unravel*(T: type, name, node: untyped): untyped =
  ## Gathers the nodes tied to `T` under `name` into a node pattern
  ## specified by `node`.
  ## 
  ## If `node` is a collection literal, each node is appended to the collection.
  ## 
  ## If `node` is a call, each node is appended to the call as an argument.
  ## 
  ## Otherwise, `node` is directly called with each node as an argument.
  var name = name
  if name.kind in {nnkOpenSymChoice, nnkClosedSymChoice}:
    name = name[0]
  expectKind name, {nnkIdent, nnkSym, nnkStrLit..nnkTripleStrLit}
  result = newCall(bindSym"unravelImpl",
    newCall(bindSym"getTypeId", T),
    newLit(name.strVal),
    node)
