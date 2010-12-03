{puts, inspect} = require 'sys'
vows = require 'vows'
assert = require 'assert'

CouchCover = require '../src/main'
fixtureDDocs = require '../fixture/ddocs'

vows.describe('CouchDB design doc function executor').addBatch({
  
  'after loading a very contrived design doc': {
    topic: -> new CouchCover.DesignDoc fixtureDDocs.contrivedDDoc

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
    
    'and then calling a function with nested requires': {
      topic: (ddoc) -> ddoc.compile('deeply.nestedRequireTest').call()
      
      'should have returned a value from the required library': (retVal) ->
        assert.equal 'foo bar??!', retVal
    }
    
    'should throw error for missing function path': (ddoc) ->
      causeError = -> ddoc.compile 'the.foo.bar'
      assert.throws causeError, CouchCover.MissingPropPathError
    
    'should throw error for non-function path': (ddoc) ->
      causeError = -> ddoc.compile 'nonFunction'
      assert.throws causeError, CouchCover.NotAFunctionError

    'should be able to pass arguments to function': (ddoc) ->
      assert.equal 9, ddoc.call 'the.squared', [3]
      
    'and then compiling and calling a function using sandbox overrides': {
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
    
    'should be able to compile/call, with overrides, in one go': {
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

