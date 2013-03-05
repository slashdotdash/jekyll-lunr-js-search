# [Jekyll](http://jekyllrb.com/) + [lunr.js](http://lunrjs.com/) = Static websites with powerful full-text search using JavaScript

Use lunr.js to provide simple full-text search in your browser for your Jekyll static website.

Inspired by Pascal Widdershoven's [Jekyll + indextank](https://github.com/PascalW/jekyll_indextank) and Michael Levin's [Sitemap.xml Generator](https://github.com/kinnetica/jekyll-plugins) plugin.

## How to use

* Place `build/jekyll_lunr_js_search.rb` inside the `_plugins` folder in the root of your jekyll site.

All pages' main content will be indexed to a `search.json` file ready for lunr.js to use.

### Requirements

Requires the following gems:

* json
* nokogiri

### Installation

    gem install nokogiri json
  
    rake build
  
    copy build/jekyll_lunr_js_search.rb to your site's _plugins folder
