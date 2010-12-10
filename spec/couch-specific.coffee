{puts, inspect} = require 'sys'
vows = require 'vows'
assert = require 'assert'

CouchCover = require '../src/main'
fixtureDDocs = require '../fixture/ddocs'

assertEmittedKVCount = (count) ->
  (result) -> assert.length result.emitted, count

assertEmittedKey = (key) ->
  (result) -> result.emitted.some (kv) -> kv.key is key

assertReturn = (expected) ->
  (retVal) -> assert.equal retVal, expected
  
orsonWells = { 
  first_name: 'Orson'
  last_name: 'Wells'
}

blogPost = {
  tags: ['rainbows', 'unicorns']
}

vows.describe('CouchCover.DesignDoc').addBatch({

  'load CouchDB function design doc': {
    topic: -> new CouchCover.DesignDoc fixtureDDocs.couchDBFuns

    'execute view map function "by-last-name"': {
      topic: (ddoc) -> ddoc.viewMap 'by-last-name', [orsonWells]

      'should emit one key-value pair': assertEmittedKVCount 1
      'should emit key "Wells"': assertEmittedKey orsonWells.last_name
    }

    'execute view map function "by-tags"': {
      topic: (ddoc) -> ddoc.viewMap 'by-tags', [blogPost]

      'should emit two key-value pairs': assertEmittedKVCount 2
      'should emit key "rainbows"': assertEmittedKey blogPost.tags[0]
      'should emit key "unicorns"': assertEmittedKey blogPost.tags[1]
    }
    
    'execute view reduce function "by-tags"': {
      topic: (ddoc) -> ddoc.viewReduce 'by-tags', [
        ['some', 'numbers', 'to', 'sum']
        [4, 6, 2, 4]
      ]
      
      'should have summed values': assertReturn 16
    }
    
    'execute update function "set-timestamp"': {
      topic: (ddoc) ->
        ddoc.update 'set-timestamp', [{ foo: 'bar'}, { what: 'ever'}]
      
      'should return timestamped doc': (retVal) ->
        assert.equal retVal[0].timestamp, '2010-10-10 14:45:52'
        assert.equal retVal[0].foo, 'bar'
    }
  }

}).export module
