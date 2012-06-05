{runInNewContext} = require 'vm'
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
    (new ViewReduceFunction @ddoc, viewName).call funArgs...
  
  update: (updateName, args...) ->
    if args.length is 1
      updateFun = new UpdateFunction @ddoc, updateName
      funArgs = args[0]
    else
      updateFun = new UpdateFunction @ddoc, updateName, args[0]
      funArgs = args[1]
    updateFun.call funArgs...
  
  filter: (filterName, funArgs=[]) ->
    (new FilterFunction @ddoc, filterName).call funArgs...
  
  require: (moduleID) ->
    modulePath = moduleID.replace '/', '.'
    code = readPath modulePath, @ddoc
    sandbox = createSandbox @ddoc, modulePath, [], { exports: {} }
    runInNewContext code, sandbox, "#{@ddoc._id}/#{moduleID}"
    sandbox.exports

class CouchFunction
  constructor: (@ddoc, @funPath, @overrides={}) ->
    @log = []
    @fileName = "#{@ddoc._id}/#{@funPath}.js"
    code = normalizeFunctionDefinition readPath @funPath, @ddoc
    sandbox = createSandbox @ddoc, @funPath, @log, @overrides
    @fun = try runInNewContext code, sandbox, @fileName catch e
    unless typeof @fun is 'function'
      throw new NotAFunctionError @funPath, @ddoc
  
  call: (funArgs...) -> @fun.apply null, funArgs

readPath = (propPath, obj) -> 
  getSubObject = (o, prop) ->
    if typeof o is 'object' and prop of o then o[prop]
    else throw new MissingPropPathError propPath, obj
  propPath.split('.').reduce getSubObject, obj
  
normalizeFunctionDefinition = (code) ->
  withoutSemicolon = code.replace /;$/, ''
  "(#{withoutSemicolon});"

createSandbox = (ddoc, propPath, logEntries, overrides) ->
  sb =
    log: (msg) -> logEntries.push msg
    require: makeRequireFun makeRefStack ddoc, propPath
  sb[name] = fun for name, fun of overrides
  sb

makeRefStack = (ddoc, funPath) ->
  stack = [ddoc]
  funPath.split('.').forEach (prop) ->
    currObj = stack[stack.length - 1]
    stack.push currObj[prop]
  stack.pop()
  stack

makeRequireFun = (refStack) ->
  (moduleID) ->
    sandbox = exports: {}
    try
      [nextRefStack, code] = findModule moduleID, refStack
      sandbox.require = makeRequireFun nextRefStack
      runInNewContext code, sandbox, moduleID
    catch e
      throw "Design doc require() error: #{e}"
    sandbox.exports

findModule = (moduleID, refStack) ->
  code = null
  nextRefStack = if /^\.\.?\//.test moduleID
    refStack.slice()
  else
    refStack.slice 0, 1
  for part in moduleID.split '/'
    if part is '..'
      nextRefStack.pop() if nextRefStack.length > 1
    else if part isnt '.'
      current = nextRefStack[nextRefStack.length - 1]
      next =  current[part]
      throw "Couldn't find part '#{part}' of '#{moduleID}'" unless next?
      nextRefStack.push next
  code = nextRefStack.pop()
  [nextRefStack, code]

class ViewMapFunction extends CouchFunction
  constructor: (@ddoc, @viewName) ->
    @emitted = emitted = []
    super @ddoc, "views.#{viewName}.map",
      emit: (k, v) -> emitted.push key: k, value: v

class ViewReduceFunction extends CouchFunction
  constructor: (@ddoc, @viewName) -> 
    super @ddoc, "views.#{viewName}.reduce",
      sum: (values) -> values.reduce ((total, n) -> total + n), 0

class UpdateFunction extends CouchFunction
  constructor: (@ddoc, @updateName, @docID) -> 
    super @ddoc, "updates.#{updateName}"
  
  call: (doc={}, req={}) ->
    req.id = @docID if @docID?
    super doc, req

class FilterFunction extends CouchFunction
  constructor: (@ddoc, @updateName) -> 
    super @ddoc, "filters.#{updateName}"

MissingPropPathError = class exports.MissingPropPathError extends Error
  constructor: (@funPath, @ddoc) ->
    @message = "Property path '#{funPath}' not found in design doc '#{@ddoc?._id}'"

NotAFunctionError = class exports.NotAFunctionError extends Error
  constructor: (@funPath, @ddoc) ->
    @message = "Property path '#{funPath}' in design doc '#{@ddoc?._id}' does not evaluate to a function"
