vows = require 'vows'
assert = require 'assert'
{puts, inspect} = require 'sys'

couchMock = require './main'

testDDoc = {
  _id: '_design/testing'
  the: {
    answer: 'function() { return 34 + 8; }'
    squared: 'function(n) { return n * n; }'
  }
  logging: 'function() { log("testing"); }'
  nonFunction: 'sorry!'
}

vows.describe('CouchDB design doc function executor').addBatch({
  
  'after loading the design doc': {
    topic: -> new couchMock.DesignDoc testDDoc

    'and then calling a function': {
      topic: (executor) -> executor.call 'the.answer'
      
      'should return 42': (retVal) ->
        assert.equal 42, retVal
    }
    
    'and then compiling a function': {
      topic: (executor) -> executor.compile 'the.answer'
      
      'should be able to invoke': (theAnswerFun) ->
        assert.equal 42, theAnswerFun.call()
    }
    
    'should throw error for missing function path': (executor) ->
      causeError = -> executor.compile 'the.foo.bar'
      assert.throws causeError, couchMock.MissingFunctionError
    
    'should throw error for non-function path': (executor) ->
      causeError = -> executor.compile 'nonFunction'
      assert.throws causeError, couchMock.NotAFunctionError

    'should be able to pass arguments to function': (executor) ->
      assert.equal 9, executor.call 'the.squared', [3]
  }
    
}).export module
