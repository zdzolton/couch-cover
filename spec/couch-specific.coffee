{puts, inspect} = require 'sys'
vows = require 'vows'
assert = require 'assert'

CouchCover = require '../src/main'
fixtureDDocs = require '../fixture/ddocs'

assertEmittedKVCount = (count) ->
  (result) -> assert.lengthOf result.emitted, count

assertEmittedKey = (key) ->
  (result) -> result.emitted.some (kv) -> kv.key is key

assertReturn = (expected) ->
  (retVal) -> assert.equal retVal, expected
  
orsonWells =
  first_name: 'Orson'
  last_name: 'Wells'

blogPost = tags: ['rainbows', 'unicorns']

vows.describe('CouchCover.DesignDoc')
  .addBatch

    'load design doc':
      topic: -> new CouchCover.DesignDoc fixtureDDocs.couchDBFuns

      'view map "by-last-name"':
        topic: (ddoc) -> ddoc.viewMap 'by-last-name', [orsonWells]

        'should emit one key-value pair': assertEmittedKVCount 1
        'should emit key "Wells"': assertEmittedKey orsonWells.last_name

      'view map "by-tags"':
        topic: (ddoc) -> ddoc.viewMap 'by-tags', [blogPost]

        'should emit two key-value pairs': assertEmittedKVCount 2
        'should emit key "rainbows"': assertEmittedKey blogPost.tags[0]
        'should emit key "unicorns"': assertEmittedKey blogPost.tags[1]
    
      'view reduce "by-tags"':
        topic: (ddoc) -> ddoc.viewReduce 'by-tags', [
          ['some', 'numbers', 'to', 'sum']
          [4, 6, 2, 4]
        ]
      
        'should have summed values': assertReturn 16
    
      'update "set-timestamp"':
        topic: (ddoc) ->
          ddoc.update 'set-timestamp', [{ foo: 'bar'}, { what: 'ever'}]
      
        'should return timestamped doc': (retVal) ->
          assert.equal retVal[0].timestamp, '2010-10-10 14:45:52'
          assert.equal retVal[0].foo, 'bar'
    
      'update "use-id" with a docid':
        topic: (ddoc) -> ddoc.update 'use-id', 'ABC123', []
        'should return': (retVal) -> assert.equal retVal[0]._id, 'ABC123'

      'filter "has-foo"':
        topic: (ddoc) -> ddoc.filter 'has-foo', [{ foo: 16 }, null]
        'should return true': (retVal) -> assert.isTrue retVal

  .export module
