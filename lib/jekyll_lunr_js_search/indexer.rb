require 'net/http'
require 'json'
require 'uri'

module Jekyll
  module LunrJsSearch
    class Indexer < Jekyll::Generator
      LUNR_URL = "https://raw.githubusercontent.com/olivernn/lunr.js/v%{version}/lunr.js"
      LOCAL_LUNR = "_plugins/lunr-%{version}.js"

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
          },
          "lunr_version" => "0.4.5"
        }.merge!(config['lunr_search'] || {})

        ver = { version: lunr_config['lunr_version'] }
        local_lunr = LOCAL_LUNR % v
        if !File.exist?(local_lunr)
          res = Net::HTTP.get_response(URI.parse(lunr_url % ver))
          raise "Could not retrieve Lunr.js #{ver[:version]} (GitHub returned #{res.code})" unless res.code == "200"
          open(local_lunr, "w") do |f|
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