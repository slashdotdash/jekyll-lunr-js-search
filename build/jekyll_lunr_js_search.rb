require 'net/http'
require 'json'
require 'uri'

module Jekyll
  module LunrJsSearch
    class Indexer < Jekyll::Generator
      LUNR_VERSION = "0.4.5"
      LUNR_URL = "https://raw.githubusercontent.com/olivernn/lunr.js/v#{LUNR_VERSION}/lunr.js"
      LOCAL_LUNR = "_plugins/lunr-#{LUNR_VERSION}.js"

      def initialize(config = {})
        super(config)
        
        lunr_config = { 
          'excludes' => [],
          'strip_index_html' => false,
          'min_length' => 3,
          'stopwords' => 'stopwords.txt',
          'fields' => {
            'title' => 10,
            'tags' => 20,
            'body' => 1
          }
        }.merge!(config['lunr_search'] || {})

        if !File.exist?(LOCAL_LUNR)
          res = Net::HTTP.get_response(URI.parse(LUNR_URL))
          raise "Could not retrieve Lunr.js (GitHub returned #{res.code})" unless res.code == "200"
          open(LOCAL_LUNR, "w") do |f|
            f.write res.body
          end
        end

        ctx = V8::Context.new
        ctx.load(LOCAL_LUNR)
        ctx['indexer'] = proc do |this|
          this.ref('id')
          lunr_config['fields'].each_pair do |name, boost|
            this.field(name, { 'boost' => boost })
          end
        end
        @index = ctx.eval('lunr(indexer)')
        @docs = {}
        @excludes = lunr_config['excludes']
        
        # if web host supports index.html as default doc, then optionally exclude it from the url 
        @strip_index_html = lunr_config['strip_index_html']

        # stop word exclusion configuration
        @min_length = lunr_config['min_length']
        @stopwords_file = lunr_config['stopwords']
      end

      # Index all pages except pages matching any value in config['lunr_excludes'] or with date['exclude_from_search']
      # The main content from each page is extracted and saved to disk as json
      def generate(site)
        puts 'Running the search indexer...'

        # gather pages and posts
        items = pages_to_index(site)
        content_renderer = PageRenderer.new(site)
        index = []

        items.each_with_index do |item, i|
          entry = SearchEntry.create(item, content_renderer)

          entry.strip_index_suffix_from_url! if @strip_index_html
          entry.strip_stopwords!(stopwords, @min_length) if File.exists?(@stopwords_file) 
          
          doc = {
            "id" => i,
            "title" => entry.title,
            "url" => entry.url,
            "date" => entry.date,
            "categories" => entry.categories,
            "body" => entry.body
          }
          @index.add(doc)
          doc.delete("body")
          @docs[i] = doc
          
          puts 'Indexed ' << "#{entry.title} (#{entry.url})"
        end
        
        # Create destination directory if it doesn't exist yet. Otherwise, we cannot write our file there.
        Dir::mkdir(site.dest) unless File.directory?(site.dest)
        
        # File I/O: create search.json file and write out pretty-printed JSON
        filename = 'index.json'
        
        total = {
          "docs" => @docs,
          "index" => @index.to_hash
        }
        File.open(File.join(site.dest, filename), "w") do |file|
          file.write(total.to_json)
        end
        puts 'Wrote index.json'

        # Keep the index.json file from being cleaned by Jekyll
        site.static_files << SearchIndexFile.new(site, site.dest, "/", filename)
      end

    private
      
      # load the stopwords file
      def stopwords
        @stopwords ||= IO.readlines(@stopwords_file).map { |l| l.strip }
      end
      
      def pages_to_index(site)
        items = []
        
        # deep copy pages
        site.pages.each {|page| items << page.dup }
        site.posts.each {|post| items << post.dup }

        # only process files that will be converted to .html and only non excluded files 
        items.select! {|i| i.output_ext == '.html' && ! @excludes.any? {|s| (i.url =~ Regexp.new(s)) != nil } } 
        items.reject! {|i| i.data['exclude_from_search'] } 
        
        items
      end
    end
  end
end
require "v8"
require "json"

class V8::Object
  def to_json
    @context['JSON']['stringify'].call(self)
  end

  def to_hash
    JSON.parse(to_json)
  end
end
require 'nokogiri'

module Jekyll
  module LunrJsSearch
    class PageRenderer
      def initialize(site)
        @site = site
      end
      
      # render the item, parse the output and get all text inside <p> elements
      def render(item)
        layoutless = item.dup
        layoutless.data = layoutless.data.dup
        layoutless.data.delete('layout')
        layoutless.render({}, @site.site_payload)
        Nokogiri::HTML(layoutless.output).text
      end
    end
  end  
end
require 'nokogiri'

module Jekyll
  module LunrJsSearch
    class SearchEntry
      def self.create(page_or_post, renderer)
        case page_or_post
        when Jekyll::Post
          date = page_or_post.date
          categories = page_or_post.categories
        when Jekyll::Page
          date = nil
          categories = []
        else 
          raise 'Not supported'
        end
        title, url = extract_title_and_url(page_or_post)
        body = renderer.render(page_or_post)

        SearchEntry.new(title, url, date, categories, body)
      end

      def self.extract_title_and_url(item)
        data = item.to_liquid
        [ data['title'], data['url'] ]
      end

      attr_reader :title, :url, :date, :categories, :body
      
      def initialize(title, url, date, categories, body)
        @title, @url, @date, @categories, @body = title, url, date, categories, body
      end
      
      def strip_index_suffix_from_url!
        @url.gsub!(/index\.html$/, '')
      end
      
      # remove anything that is in the stop words list from the text to be indexed
      def strip_stopwords!(stopwords, min_length)
        @body = @body.split.delete_if() do |x| 
          t = x.downcase.gsub(/[^a-z]/, '')
          t.length < min_length || stopwords.include?(t)
        end.join(' ')
      end
    end
  end
end
module Jekyll
  module LunrJsSearch  
    class SearchIndexFile < Jekyll::StaticFile
      # Override write as the search.json index file has already been created 
      def write(dest)
        true
      end
    end
  end
end
module Jekyll
  module LunrJsSearch
    VERSION = "0.1.1"
  end
end
