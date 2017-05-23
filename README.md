# [Jekyll](http://jekyllrb.com/) + [lunr.js](http://lunrjs.com/) = Static websites with powerful full-text search using JavaScript

Use [lunr.js](http://lunrjs.com/) to provide simple full-text search, using JavaScript in your browser, for your Jekyll static website.

Inspired by Pascal Widdershoven's [Jekyll + indextank](https://github.com/PascalW/jekyll_indextank) and Michael Levin's [Sitemap.xml Generator](https://github.com/kinnetica/jekyll-plugins) plugins.

This Jekyll plugin handles the generation of a lunr.js compatible `.json` index file. Runtime search configuration is provided by a simple jQuery plugin.

It allows full-text search of all your Jekyll pages and posts. Executed by the client without any server-side processing (outside of serving static files).

## How to use

### 1. Install the plugin

Choose to install as either a Ruby Gem, or by copying the pre-built plugin file to your Jekyll site.

#### 1a. Install as a Ruby Gem

1. Install the [jekyll-lunr-js-search](https://rubygems.org/gems/jekyll-lunr-js-search) Ruby Gem.

        gem install jekyll-lunr-js-search

2. Modify your Jekyll `_config.yml` file to include the Gem.

        gems: ['jekyll-lunr-js-search']

#### 1b. Install by copying the plugin to your Jekyll site.

1. Place `build/jekyll_lunr_js_search.rb` inside the `_plugins` folder in the root of your Jekyll site.

The content from all Jekyll posts and pages will be indexed to a `js/index.json` file ready for lunr.js to consume. This happens each time the site is generated.

A jQuery plugin is provided in `js/jquery.lunr.search.js` to handle the configuration of lunr.js with the search index JSON data generated by this plugin.

Dependencies for the jQuery plugin are as follows.

* [jQuery](http://jquery.com)
* [lunr.js](http://lunrjs.com)
* [Mustache.js](https://github.com/janl/mustache.js)
* [date.format.js](http://blog.stevenlevithan.com/archives/date-time-format)
* [URI.js](http://medialize.github.com/URI.js/)

A pre-built version of the jQuery plugin, along with all of the above dependencies, concatenated and minified is available from at [build/search.min.js](https://github.com/slashdotdash/jekyll-lunr-js-search/blob/master/build/search.min.js).

### 2. Copy the jQuery plugin and add a script reference.

#### 2a. Using the pre-built, minified plugin from the gem.

The plugin will automatically add the minified JavaScript file `js/search.min.js` to your `_site`.

To use it, you must add a script reference to the bottom of your nominated search page.

        <script src="/js/search.min.js" type="text/javascript" charset="utf-8"></script>

#### 2b. Using the jQuery plugin and managing its dependencies yourself.

1. Copy `js/jquery.lunr.search.js` to your Jekyll site's JavaScript directory.
2. Add a script reference to the bottom of your nominated search page for `jquery.lunr.search.js` and each of the dependencies outlined above.

        <script src="/js/jquery-1.9.1.min.js" type="text/javascript" charset="utf-8"></script>
        <script src="/js/lunr.min.js" type="text/javascript" charset="utf-8"></script>
        <script src="/js/mustache.js" type="text/javascript" charset="utf-8"></script>
        <script src="/js/date.format.js" type="text/javascript" charset="utf-8"></script>
        <script src="/js/URI.min.js" type="text/javascript" charset="utf-8"></script>
        <script src="/js/jquery.lunr.search.js" type="text/javascript" charset="utf-8"></script>

Make sure you use the same version of lunr.js as the gem. The Jekyll log output includes the version used.

Ideally you would concatenate, minify and optimise these six `.js` files using uglify/Google closure/etc to produce a single `search.min.js` file to reference (or use the pre-built script as described in 2a above).

    <script src="/js/search.min.js" type="text/javascript" charset="utf-8"></script>

### 4. Add a search form with a query input as shown.

    <form action="/search" method="get">
      <input type="text" id="search-query" name="q" placeholder="Search" autocomplete="off">
    </form>

Search happens as you type, once at least three characters have been entered.

Providing the form action and specifying the get method allows the user to hit return/enter to also submit the search.
Amend the form's action URL as necessary for the search page on your own site.

### 5. Add an element to contain the list of search result entries.

    <section id="search-results" style="display: none;"> </section>

This may be initially hidden as the plugin will show the element when searching.

### 6. Create a Mustache template to display the search results.

    {% raw %}
    <script id="search-results-template" type="text/mustache">
      {{#entries}}
        <article>
          <h3>
            {{#date}}<small><time datetime="{{pubdate}}" pubdate>{{displaydate}}</time></small>{{/date}}
            <a href="{{url}}">{{title}}</a>
          </h3>
          {{#is_post}}
          <ul>
            {{#tags}}<li>{{.}} </li>{{/tags}}
          </ul>
          {{/is_post}}
        </article>
      {{/entries}}
    </script>
    {% endraw %}

Note the use of `{% raw %}` and `{% endraw %}` to ensure the Mustache tags are not stripped out by Jekyll.

The fields available to display are as follows.

#### entries
List of search result entries (mandatory).
#### date
Raw published date for posts, or null for pages. Can be used to toggle display of the following dates in the template `{{#date}}has a date{{/date}} {{#!date}}no date{{/date}}`.
#### pubdate
Post published date, formatted as 'yyyy-mm-dd', to be used in a html5 `<time datetime="{{pubdate}}">` element (posts only).
#### displaydate
Post published date, formatted as 'mmm dd, yyyy', such as Oct 12, 2012 (posts only)
#### title
Title of the Jekyll page or post.
#### url
URL of the Jekyll page or post that can be used to create a hyperlink `<a href="{{url}}">{{title}}</a>`.
#### categories
Categories (array) of the Jekyll page or post, can be used in a loop `{{#categories}}{{.}} {{/categories}}` to list them.
#### tags
Tags (array) of the Jekyll page or post, can be used in a loop `{{#tags}}{{.}} {{/tags}}` to list them.
#### is_post
Booelan value, true if current result element is a post. Can be used to toggle display of specific elements in the template `{{#is_post}}is a post{{/is_post}}`

### 7. Configure the jQuery plugin for the search input field.

    <script type="text/javascript">
      $(function() {
        $('#search-query').lunrSearch({
          indexUrl  : '/js/index.json',           // url for the .json file containing search index data
          results   : '#search-results',          // selector for containing search results element
          template  : '#search-results-template', // selector for Mustache.js template
          titleMsg  : '<h1>Search results<h1>',   // message attached in front of results (can be empty)
          emptyMsg  : '<p>Nothing found.</p>'     // shown message if search returns no results
        });
      });
    </script>

### 8. To exclude pages from the search index.

Add the following `exclude_from_search` setting to any page's YAML config.

    exclude_from_search: true

Or add an array of exclusions (as individual regular expressions) to the site's `_config.yml` file.

    lunr_search:
      excludes: [rss.xml, atom.xml]

### 9. Stop Words

You can also configure a stopwords file, and a minimum length of word to be included in the index file. This can be done by adding a search block to `_config.yml`. The default values are:

    lunr_search:
      stopwords: "stopwords.txt"
      min_length: 3

The stopwords file must consist of one word per line, in lowercase, without punctuation.

### 10. Alternate data directory

You can choose to store `index.json`, `search.min.js` and `lunr.min.js` in a different directory like this:

    lunr_search:
      js_dir: "javascript"

## 11. Indexed Fields and Field Boost
 
To customize which fields are indexed with what weight the "fields" map can be overridden,
e.g. to also make custom front matter fields searchable. 
The defaults are:

    lunr_search: 
      fields:
        title: 10
        categories: 20
        tags: 20
        body: 1
        
`title`, `date`, `url`, `is_post` and the `body` are special names for Jekyll built-ins. 

## 12. Stored Document Data for use in the Template

To customize which fields' full values are put into the `index.json` file for use in the search results template,
a `template_fields` list can be configured.
E.g. you can add a custom `description` front matter field for the preview or exclude fields to reduce the index file size. 
The fields do not necessarily be indexed, too. The defaults are: 

    lunr_search: 
      template_fields:
        - title
        - url
        - date
        - categories
        - tags
        - is_post

Please note that adding the `body` as a template field will make your `index.json` file unsusably large.  

## Demo

Search plugin is deployed to [10consulting.com/search](http://10consulting.com/search/).
Some example search queries are [/search/?q=git](http://10consulting.com/search/?q=git), [/search/?q=cqrs](http://10consulting.com/search/?q=cqrs).

It also features on-demand loading of the search plugin `.js` when focusing into the search field on the [homepage](http://10consulting.com/). Look at the browser network requests clicking into the search input.

## Building

To build the single `jekyll_lunr_js_search.rb` plugin file.

### Requirements

Install [Bundler](http://bundler.io/) and then run the following.

	bundle install

Install [Bower](http://bower.io).

To build the plugin.

    rake build

Then copy `build/jekyll_lunr_js_search.rb` to your Jekyll site's `_plugins` folder and the `build/*.min.js` files to your site's `js` folder.

If you include the `.js` and `.js.map` files your browser developer console will link to the unminified code.