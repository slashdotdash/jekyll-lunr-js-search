(function($) {

  var debounce = function(fn) {
    var timeout;
    var slice = Array.prototype.slice;

    return function() {
      var args = slice.call(arguments),
          ctx = this;

      clearTimeout(timeout);

      timeout = setTimeout(function () {
        fn.apply(ctx, args);
      }, 100);
    };
  };
  
  // parse a date in yyyy-mm-dd format
  var parseDate = function(input) {
    var parts = input.match(/(\d+)/g);
    return new Date(parts[0], parts[1]-1, parts[2]); // months are 0-based
  }
  
  var LunrSearch = (function() {
    function LunrSearch(elem, options) {
      this.$elem = elem;      
      this.$results = $(options.results),
      this.$entries = $(options.entries, this.$results),
      this.indexDataUrl = options.indexUrl;
      this.index = this.createIndex();
      this.template = this.compileTemplate($(options.template));
      
      this.initialize();
    };
        
    LunrSearch.prototype.initialize = function() {
      var self = this;
      
      this.loadIndexData(function(data) {
        self.populateIndex(data);
        self.populateSearchFromQuery();
        self.bindKeypress();
      });
    };
    
    // create lunr.js search index specifying that we want to index the title and body fields of documents.
    LunrSearch.prototype.createIndex = function() {
      return lunr(function() {
        this.field('title', { boost: 10 });
        this.field('body');
        this.ref('id');      
      });
    };
    
    // compile search results template
    LunrSearch.prototype.compileTemplate = function($template) {      
      return Mustache.compile($template.text());
    };
        
    // load the search index data
    LunrSearch.prototype.loadIndexData = function(callback) {
      $.getJSON(this.indexDataUrl, callback);
    };
    
    LunrSearch.prototype.populateIndex = function(data) {
      var index = this.index;
          
      // format the raw json into a form that is simpler to work with
      this.entries = $.map(data.entries, this.createEntry);

      $.each(this.entries, function(idx, entry) {
        index.add(entry);
      });
    };

    LunrSearch.prototype.createEntry = function(raw, index) {
      var entry = $.extend({
        id: index + 1
      }, raw);
      
      // include pub date for posts
      if (raw.date) {
        $.extend(entry, {
          date: parseDate(raw.date),
          pubdate: function() {
            // HTML5 pubdate
            return dateFormat(parseDate(raw.date), 'yyyy-mm-dd')
          },
          displaydate: function() {
            // only for posts (e.g. Oct 12, 2012)
            return dateFormat(parseDate(raw.date), 'mmm dd, yyyy');
          }
        });
      }
      
      return entry;
    };
    
    LunrSearch.prototype.bindKeypress = function() {
      var self = this;

      this.$elem.bind('keyup', debounce(function() {
        self.search($(this).val());
      }));
    };
    
    LunrSearch.prototype.search = function(query) {
      var entries = this.entries;
      
      if (query.length <= 2) {
        this.$results.hide();
        this.$entries.empty();
      } else {
        var results = $.map(this.index.search(query), function(result) {
          return $.grep(entries, function(entry) { return entry.id === parseInt(result.ref, 10) })[0];
        });
        
        this.displayResults(results);
      }
    };
    
    LunrSearch.prototype.displayResults = function(entries) {
      var $entries = this.$entries,
        $results = this.$results;
        
      $entries.empty();
      
      if (entries.length === 0) {
        $entries.append('<p>Nothing found.</p>')
      } else {
        $entries.append(this.template({entries: entries}));
      }
      
      $results.show();
    };
    
    // Populate the search input with 'q' querystring parameter if set
    LunrSearch.prototype.populateSearchFromQuery = function() {
      var uri = new URI(window.location.search.toString());
      var queryString = uri.search(true);

      if (queryString.hasOwnProperty('q')) {
        this.$elem.val(queryString.q);
        this.search(queryString.q.toString());
      }
    };
    
    return LunrSearch;
  })();

  $.fn.lunrSearch = function(options) {
    // apply default options
    options = $.extend({}, $.fn.lunrSearch.defaults, options);      

    // create search object
    new LunrSearch(this, options);
    
    return this;
  };
  
  $.fn.lunrSearch.defaults = {
    indexUrl  : '/search.json',     // Url for the .json file containing search index source data (containing: title, url, date, body)
    results   : '#search-results',  // selector for containing search results element
    entries   : '.entries',         // selector for search entries containing element (contained within results above)
    template  : '#search-results-template'  // selector for Mustache.js template
  };
})(jQuery);