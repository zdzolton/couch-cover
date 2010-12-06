{puts, inspect} = require 'sys'
vows = require 'vows'
assert = require 'assert'

CouchCover = require '../src/main'
fixtureDDocs = require '../fixture/ddocs'

assertEmittedKVCount = (count) ->
  (result) -> assert.equal result.emitted.length, count

assertEmittedKey = (key) ->
  (result) -> result.emitted.some (kv) -> kv.key is key

assertReturn = (expected) ->
  (retVal) -> assert.equal retVal, expected

vows.describe('CouchCover.DesignDoc').addBatch({

  'load CouchDB function design doc': {
    topic: -> new CouchCover.DesignDoc fixtureDDocs.couchDBFuns

    'execute view map function "by-last-name"': {
      topic: (ddoc) -> ddoc.viewMap 'by-last-name', { 
        first_name: 'Orson'
        last_name: 'Wells'
      }

      'should emit one key-value pair': assertEmittedKVCount 1
      'should emit key "Wells"': assertEmittedKey 'Wells'
    }

    'execute view map function "by-tags"': {
      topic: (ddoc) -> ddoc.viewMap 'by-tags', {
        tags: ['rainbows', 'unicorns']
      }

      'should emit two key-value pairs': assertEmittedKVCount 2
      'should emit key "rainbows"': assertEmittedKey 'rainbows'
      'should emit key "unicorns"': assertEmittedKey 'unicorns'
    }
    
    'execute view reduce function "by-tags"': {
      topic: (ddoc) -> ddoc.viewReduce 'by-tags', {
        keys: ['some', 'numbers', 'to', 'sum']
        values: [4, 6, 2, 4]
      }
      
      'should have summed values': assertReturn 16
    }
  }

}).export module
