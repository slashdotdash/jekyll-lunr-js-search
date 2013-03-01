# Jekyll + lunr.js = Static websites with powerful full-text search using JavaScript

## How to use

* Place jekyll_lunr_js_search.rb inside the `_plugins` folder in the root of your jekyll site.

All pages' main content will be indexed to a `search.json` file ready for lunr.js to use.

### Requirements

Requires the following gems:

* json
* nokogiri

### Installation

  gem install nokogiri json
  rake build
  copy build/jekyll_lunr_js_search.rb to your site's _plugins folder
