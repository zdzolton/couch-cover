vows = require 'vows'
assert = require 'assert'
{puts, inspect} = require 'sys'
p = (o) -> puts inspect o

couchMock = require './main'

testDDoc = {
  _id: '_design/testing'
  the: {
    answer: 'function() { return 34 + 8; }'
    squared: 'function(n) { return n * n; }'
  }
  logging: 'function() { log("testing"); }'
  nonFunction: 'sorry!'
  requireTest: 'function(s) { return require("lib/simple").foo(s); }'
  deeply: { nested: {
    requireTest: 'function() { return require("../../lib/simple").foo("DEEP?"); }'
  } }
  lib: {
    simple: '''
      exports.foo = function(s) {
        return 'foo ' + s + '!';
      }
    '''
  }
}

vows.describe('CouchDB design doc function executor').addBatch({
  
  'after loading the design doc': {
    topic: -> new couchMock.DesignDoc testDDoc

    'and then calling a function': {
      topic: (ddoc) -> ddoc.call 'the.answer'
      
      'should return 42': (retVal) ->
        assert.equal 42, retVal
    }
    
    'and then compiling a function': {
      topic: (ddoc) -> ddoc.compile 'the.answer'
      
      'should be able to invoke': (theAnswerFun) ->
        assert.equal 42, theAnswerFun.call()
    }
    
    'and then compiling a function using sandboxed log function': {
      topic: (ddoc) -> ddoc.compile 'logging'
      
      'should have no log messages yet': (fun) ->
        assert.isEmpty fun.log

      'should be able to a log message': (fun) ->
        fun.call()
        assert.equal 1, fun?.log?.length
        fun.call(); fun.call()
        assert.equal 3, fun?.log?.length
    }
    
    'and then calling a function using sandboxed require function': {
      topic: (ddoc) -> ddoc.compile('requireTest').call 'GOTYA'
      
      'should have returned a value from the required library': (retVal) ->
        assert.equal 'foo GOTYA!', retVal
    }
    
    'and then calling a function requiring a module higher in hierarchy': {
      topic: (ddoc) -> ddoc.compile('deeply.nested.requireTest').call()
      
      'should have returned a value from the required library': (retVal) ->
        assert.equal 'foo DEEP?!', retVal
    }
    
    'should throw error for missing function path': (ddoc) ->
      causeError = -> ddoc.compile 'the.foo.bar'
      assert.throws causeError, couchMock.MissingPropPathError
    
    'should throw error for non-function path': (ddoc) ->
      causeError = -> ddoc.compile 'nonFunction'
      assert.throws causeError, couchMock.NotAFunctionError

    'should be able to pass arguments to function': (ddoc) ->
      assert.equal 9, ddoc.call 'the.squared', [3]
  }
    
}).run() #export module
