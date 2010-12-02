{runInNewContext} = process.binding('evals').Script
{puts, inspect} = require 'sys'

class exports.DesignDoc
  constructor: (@ddoc) ->
  
  compile: (funPath) ->
    new CouchFunction @ddoc, funPath
  
  call: (funPath, funArgs=[]) ->
    @compile(funPath).call funArgs...

class CouchFunction
  constructor: (@ddoc, @funPath) ->
    @log = []
    fileName = "#{@ddoc._id}/#{@funPath}.js"
    code = "(#{readPath @funPath, @ddoc});"
    sandbox = createSandbox @
    try
      @fun = runInNewContext code, sandbox, fileName
    catch e
    if typeof @fun isnt 'function'
      throw new NotAFunctionError @funPath, @ddoc
  
  call: (funArgs...) ->
    @fun.apply null, funArgs

readPath = (propPath, obj) ->
  getSubObject = (o, prop) ->
    if typeof o is 'object' and prop of o
      o[prop]
    else
      throw new MissingFunctionError propPath, obj
  propPath.split('.').reduce getSubObject, obj

createSandbox = (couchFun) ->
  {
    log: (msg) -> couchFun.log.push msg
    require: (moduleID) -> { foo: -> 'foo via lib!' }
  }

class exports.MissingFunctionError extends Error
  constructor: (@funPath, @ddoc) ->
    @message = "Function '#{funPath}' not found in design doc '#{@ddoc._id}'"

class exports.NotAFunctionError extends Error
  constructor: (@funPath, @ddoc) ->
    @message = "Property path '#{funPath}' in design doc '#{@ddoc._id}' does not evaluate to a function"
