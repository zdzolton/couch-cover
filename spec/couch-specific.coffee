{puts, inspect} = require 'sys'
vows = require 'vows'
assert = require 'assert'

CouchCover = require '../src/main'
fixtureDDocs = require '../fixture/ddocs'

vows.describe('CouchCover.DesignDoc').addBatch({

  'load CouchDB function design doc': {
    topic: -> new CouchCover.DesignDoc fixtureDDocs.couchDBFuns

    'execute view map function "by-last-name"': {
      topic: (ddoc) -> ddoc.viewMap 'by-last-name', { 
        first_name: 'Orson'
        last_name: 'Wells'
      }

      'should emit one key-value pair': (result) ->
        assert.equal result.emitted.length, 1

      'should emit key "Wells"': (result) ->
        assert.equal result.emitted[0].key, 'Wells'
    }

    'execute view map function "by-tags"': {
      topic: (ddoc) -> ddoc.viewMap 'by-tags', {
        tags: ['rainbows', 'unicorns']
      }

      'should emit two key-value pairs': (result) ->
        assert.equal result.emitted.length, 2

      'should emit key "rainbows"': (result) ->
        assert.equal result.emitted[0].key, 'rainbows'

      'should emit key "unicorns"': (result) ->
        assert.equal result.emitted[1].key, 'unicorns'
    }
  }

}).export module
