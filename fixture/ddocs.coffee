exports.basics = {
  _id: '_design/testing'
  
  the: {
    answer: 'function() { return 34 + 8; }'
    squared: 'function(n) { return n * n; }'
  }
  
  logging: 'function() { log("testing"); }'
  nonFunction: 'sorry!'
  requireTest: 'function(s) { return require("lib/simple").foo(s); }'
  
  deeply: { 
    nested: {
      requireTest: 'function() { return require("../../lib/simple").foo("DEEP?"); }'
    }
    'nested-require-test': 'function() { return require("../lib/alsoRequires").bar(); }'
  }
  
  lib: {
    simple: '''
      exports.foo = function(s) {
        return 'foo ' + s + '!';
      };
    '''
    alsoRequires: '''
      var simple = require('simple');
      exports.bar = function() {
        return simple.foo('bar??')
      };
    '''
  }
}

exports.couchDBFuns = {
  views: {
    'by-last-name': {
      map: 'function(doc) { emit(doc.last_name, null); }'
    }
    
    'by-tags': {
      map: '''
        function(doc) {
          doc.tags.forEach(function(t) {
            emit(t, null);
          });
        }
      '''
      
      reduce: '''
        function(keys, values) { return sum(values); }
      '''
    }
  }
}
