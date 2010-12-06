{runInNewContext} = process.binding('evals').Script
{puts, inspect} = require 'sys'

class exports.DesignDoc
  constructor: (@ddoc) ->
  
  compile: (funPath, overrides={}) ->
    new CouchFunction @ddoc, funPath, overrides
  
  call: (funPath, funArgs=[], overrides={}) ->
    @compile(funPath, overrides).call funArgs...
  
  viewMap: (viewName, funArgs=[]) ->
    fun = new ViewMapFunction @ddoc, viewName
    retVal = fun.call funArgs...
    { returned: retVal, emitted: fun.emitted }
  
  viewReduce: (viewName, funArgs=[]) ->
    fun = new ViewReduceFunction @ddoc, viewName
    fun.call funArgs...

class CouchFunction
  constructor: (@ddoc, @funPath, @overrides={}) ->
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

class ViewMapFunction extends CouchFunction
  constructor: (@ddoc, @viewName) ->
    @emitted = emitted = []
    super @ddoc, "views.#{viewName}.map", {
      emit: (k, v) -> emitted.push { key: k, value: v }
    }

class ViewReduceFunction extends CouchFunction
  constructor: (@ddoc, @viewName) -> 
    super @ddoc, "views.#{viewName}.reduce", {
      sum: (values) -> values.reduce ((total, n) -> total + n), 0
    }

readPath = (propPath, obj) -> 
  getSubObject = (o, prop) ->
    if typeof o is 'object' and prop of o
      o[prop]
    else
      throw new MissingPropPathError propPath, obj
  propPath.split('.').reduce getSubObject, obj

createSandbox = (couchFun) ->
  sb = {
    log: (msg) -> couchFun.log.push msg
    require: makeRequireFun makeInitialRefStack couchFun
  }
  sb[name] = fun for name, fun of couchFun.overrides
  sb

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
