{runInNewContext} = process.binding('evals').Script
{puts, inspect} = require 'sys'

class exports.DesignDoc
  constructor: (@ddoc) ->
  
  compile: (funPath) ->
    new CouchFunction @ddoc, funPath
  
  call: (funPath, funArgs=[]) ->
    @compile(funPath).call funArgs

class CouchFunction
  constructor: (@ddoc, @funPath) ->
    fileName = "#{@ddoc._id}/#{@funPath}.js"
    code = "(#{readPath @funPath, @ddoc});"
    sandBox = createSandbox @ddoc
    @fun = runInNewContext code, sandBox, fileName
    if typeof @fun isnt 'function'
      throw "#{fileName} does not evaluate to a function"
  
  call: (funArgs=[]) ->
    @fun.apply null, funArgs

class exports.CouchMissingFunctionError extends Error
  constructor: (@funPath, @ddoc) ->
    @message = "Function '#{funPath}' not found in design doc '#{@ddoc._id}'"

readPath = (propPath, obj) ->
  getSubObject = (o, prop) ->
    if typeof o is 'object' and prop of o
      o[prop]
    else
      throw new CouchMissingFunctionError propPath, obj
  propPath.split('.').reduce getSubObject, obj

createSandbox = (ddoc, funPath, overrides) -> 
  # require: makeRequireFun refStack,
  {
    log: makeLogFun ddoc, funPath
  }

makeLogFun = (ddoc, funPath) -> 
  (objOrString) ->
    msg = if typeof objOrString is 'string'
      objOrString
    else
      inspect objOrString
    puts "Log - #{ddoc._id}/#{funPath} - #{msg}"

# if (typeof fun !== 'function') {
#   throw fullName + ' does not evaluate to a function';
# }

# function makeRequireFun(initialRefStack) {
#   return function(moduleID) {
#     if (/^\.\.?(\/[^\/]+)+/.test(moduleID)) {
#       log('DEBUG', 'Resolving module from design doc', moduleID);
#       return resolveModuleRequire(moduleID, initialRefStack.slice());
#     } else {
#       log('DEBUG', 'Resolving module from Node.JS require paths', moduleID);
#       return require(moduleID);
#     }
#   };
# }

# function resolveModuleRequire(moduleID, refStack) {
#   moduleID.split('/').forEach(function(part) {
#     if (part == '..') {
#       refStack.pop();
#     } else if (part != '.') {
#       var current = refStack[refStack.length - 1];
#       var next =  current[part];
#       if (!next) throw "Cannot find module in design doc '" + moduleID + "'";
#       refStack.push(next);
#     }
#   });
#   var code = refStack.pop();
#   var context = {
#     exports: {},
#     require: makeRequireFun(refStack)
#   };
#   process.evalcx(code, context, moduleID);
#   return context.exports;
# }
