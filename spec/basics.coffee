{puts, inspect} = require 'sys'
vows = require 'vows'
assert = require 'assert'

CouchCover = require '../src/main'
fixtureDDocs = require '../fixture/ddocs'

assertReturn = (expected) ->
  (retVal) -> assert.equal retVal, expected

assertCompilingThrows = (funPath, errorType) ->
  (ddoc) ->
    causeError = -> ddoc.compile funPath
    assert.throws causeError, errorType

ddocCall = (funPath, args=[]) ->
  (ddoc) -> 
    try
      ddoc.call funPath, args
    catch e

vows.describe('CouchCover.DesignDoc').addBatch({
  
  'load basic functionality design doc': {
    topic: -> new CouchCover.DesignDoc fixtureDDocs.basics

    'call "the.answer"': {
      topic: -> ddocCall 'the.answer'
      'should return 42': -> assertReturn 42
    }
    
    'compile "the.answer"': {
      topic: (ddoc) -> ddoc.compile 'the.answer'
      'should be able to invoke': (fun) -> assert.equal fun.call(), 42
    }
    
    'compile a function using sandboxed log()': {
      topic: (ddoc) -> ddoc.compile 'logging'

      'calling should log messages': (fun) ->
        assert.isEmpty fun.log
        fun.call()
        assert.equal fun?.log?.length, 1
        fun.call(); fun.call()
        assert.equal fun?.log?.length, 3
    }
    
    'call a function using sandboxed require function': {
      topic: ddocCall 'requireTest', ['GOTYA']
      'should return value from argument': assertReturn 'foo GOTYA!'
    }
    
    'call a function requiring a module higher in hierarchy': {
      topic: ddocCall 'deeply.nested.requireTest'
      'should return value from argument': assertReturn 'foo DEEP?!'
    }
    
    'call a function with nested requires': {
      topic: ddocCall 'deeply.nested-require-test'
      'should return value from argument': assertReturn 'foo bar??!'
    }
    
    'should throw error for missing function path':
      assertCompilingThrows 'the.foo.bar', CouchCover.MissingPropPathError
    
    'should throw error for non-function path': 
      assertCompilingThrows 'nonFunction', CouchCover.NotAFunctionError

    'should be able to pass arguments to function': (ddoc) ->
      retVal = ddoc.call 'the.squared', [3]
      assert.equal retVal, 9
      
    'compile then call a function using overriden log()': {
      topic: (ddoc) ->
        logWasCalled = false
        fun = ddoc.compile 'logging', {
          log: (s) -> logWasCalled = "ok: #{s}"
        }
        fun.call()
        logWasCalled
        
      'should have called overridden log() function': (logWasCalled) ->
        assert.equal logWasCalled, "ok: testing"
    }
    
    'call a function, with overriden log(), directly': {
       topic: (ddoc) ->
         logWasCalled = false
         ddoc.call 'logging', [], {
           log: (s) -> logWasCalled = "ok: #{s}"
         }
         logWasCalled

       'should have called overridden log() function': (logWasCalled) ->
         assert.equal logWasCalled, "ok: testing"
    }
  }
  
}).export module
