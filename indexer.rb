require 'rubygems'
require 'json'

module Jekyll

  class Indexer < Generator

    def initialize(config = {})
      super(config)
      
      @excludes = config['lunr_excludes'] || []
      
      # if web host supports index.html as default doc, then optionally exclude it from the url 
      @strip_index_html = config['lunr_strip_index_html'] || false

      @min_length = config['search']['min_length'] || 3
      @stopwords_file = config['search']['stopwords'] || 'stopwords.txt'
    end

    # Index all pages except pages matching any value in config['lunr_excludes'] or with date['exclude_from_search']
    # The main content from each page is extracted and saved to disk as json
    def generate(site)
      puts 'Running the search indexer...'

      # gather pages and posts
      items = pages_to_index(site)
      content_renderer = PageRenderer.new(site)
      index = []

      items.each do |item|
        entry = SearchEntry.create(item, content_renderer)

        entry.strip_index_suffix_from_url! if @strip_index_html

        index << {
          :title => entry.title, 
          :url => entry.url,
          :date => entry.date,
          :categories => entry.categories,
          :body => strip_stopwords(entry.body)
        }
        
        puts 'Indexed ' << "#{entry.title} (#{entry.url})"
        # $stdout.print(".");$stdout.flush;
      end
      
      json = JSON.generate({:entries => index})
      
      # Create destination directory if it doesn't exist yet. Otherwise, we cannot write our file there.
      Dir::mkdir(site.dest) unless File.directory?(site.dest)
      
      # File I/O: create search.json file and write out pretty-printed JSON
      filename = 'search.json'
      
      File.open(File.join(site.dest, filename), "w") do |file|
        file.write(json)
      end

      # Keep the search.json file from being cleaned by Jekyll
      site.static_files << Jekyll::SearchIndexFile.new(site, site.dest, "/", filename)

      puts ''
    end

  private
    # load the stopwords file
    def stopwords
      @stopwords = IO.readlines(@stopwords_file).map { |l| l.strip } unless @stopwords
      @stopwords
    end
    def strip_stopwords(text) 
      # remove anything that is in the stop words list from the text to be indexed
      s = stopwords()
      text.split.delete_if() do |x| 
        t = x.downcase.gsub(/[^a-z]/,'')
        t.length < @min_length || s.include?(t)
      end.join(' ')
    end
    def pages_to_index(site)
      # Deep copy pages
      items = []
      site.pages.each {|page| items << page.dup }
      site.posts.each {|post| items << post.dup }

      # only process files that will be converted to .html and only non excluded files 
      items.select! {|i| i.output_ext == '.html' && ! @excludes.any? {|s| (i.url =~ Regexp.new(s)) != nil } } 
      items.reject! {|i| i.data['exclude_from_search'] } 
      
      items
    end
  end
end