lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll_lunr_js_search/version'

Gem::Specification.new do |s|
  s.name          = 'jekyll-lunr-js-search'
  s.version       = Jekyll::LunrJsSearch::VERSION
  s.licenses      = ['MIT']
  s.summary       = 'Jekyll + lunr.js = static websites with powerful full-text search using JavaScript'
  s.description   = 'Use lunr.js to provide simple full-text search, using JavaScript in your browser, for your Jekyll static website.'
  s.authors       = ['Ben Smith']
  s.email         = 'ben@10consulting.com'
  s.files         = [
    'lib/jekyll-lunr-js-search.rb', 
    'lib/jekyll_lunr_js_search/indexer.rb', 
    'lib/jekyll_lunr_js_search/page_renderer.rb',
    'lib/jekyll_lunr_js_search/search_entry.rb',
    'lib/jekyll_lunr_js_search/search_index_file.rb',
    'lib/jekyll_lunr_js_search/version.rb',
  ]
  s.homepage      = 'https://github.com/slashdotdash/jekyll-lunr-js-search'
  s.require_paths = ['lib']
  
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_runtime_dependency 'json', '~> 1.8'

  s.add_development_dependency 'rake', '~> 10.3'
  s.add_development_dependency 'uglifier', '~> 2.5'
end