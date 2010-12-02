{runInNewContext} = process.binding('evals').Script
{puts, inspect} = require 'sys'

class exports.DesignDoc
  constructor: (@ddoc) ->
  
  compile: (funPath) -> new CouchFunction @ddoc, funPath
  
  call: (funPath, funArgs=[]) -> @compile(funPath).call funArgs...

class CouchFunction
  constructor: (@ddoc, @funPath) ->
    @log = []
    @fileName = "#{@ddoc._id}/#{@funPath}.js"
    code = "(#{readPath @funPath, @ddoc});"
    sandbox = createSandbox @
    try
      @fun = runInNewContext code, sandbox, @fileName
    catch e
    unless typeof @fun is 'function'
      throw new NotAFunctionError @funPath, @ddoc
  
  call: (funArgs...) -> @fun.apply null, funArgs

readPath = (propPath, obj) -> 
  getSubObject = (o, prop) ->
    if typeof o is 'object' and prop of o
      o[prop]
    else
      throw new MissingPropPathError propPath, obj
  propPath.split('.').reduce getSubObject, obj

createSandbox = (couchFun) ->
  {
    log: (msg) -> couchFun.log.push msg
    require: makeRequireFun makeInitialRefStack couchFun
  }

makeInitialRefStack = (couchFun) ->
  stack = [couchFun.ddoc]
  couchFun.funPath.split('.').forEach (prop) ->
    currObj = stack[stack.length - 1]
    stack.push currObj[prop]
  stack.pop()
  stack

makeRequireFun = (refStack) ->
  (moduleID) ->
    sandbox = { exports: {} }
    try
      [nextRefStack, code] = findModule moduleID, refStack
      sandbox.require = makeRequireFun nextRefStack
      runInNewContext code, sandbox, moduleID
    catch e
      throw "Design doc require() error: #{e.message}"
    sandbox.exports

findModule = (moduleID, refStack) ->
  for part in moduleID.split '/'
    if part is '..'
      refStack.pop()
    else if part isnt '.'
      current = refStack[refStack.length - 1]
      next =  current[part]
      throw "Couldn't find part: #{part}" moduleID unless next?
      refStack.push next
  code = refStack.pop()
  [refStack, code]

class exports.MissingPropPathError extends Error
  constructor: (@funPath, @ddoc) ->
    @message = "Property path '#{funPath}' not found in design doc '#{@ddoc._id}'"

class exports.NotAFunctionError extends Error
  constructor: (@funPath, @ddoc) ->
    @message = "Property path '#{funPath}' in design doc '#{@ddoc._id}' does not evaluate to a function"
