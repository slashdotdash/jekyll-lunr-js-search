require 'rubygems'
require 'json'

module Jekyll

  class Indexer < Generator

    def initialize(config = {})
      super(config)
      
      @excludes = config['lunr_excludes'] || []
      
      # if web host supports index.html as default doc, then optionally exclude it from the url 
      @strip_index_html = config['lunr_strip_index_html'] || false
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
          :body => entry.body
        }
        
        puts 'Indexed ' << "#{entry.title} (#{entry.url})"
        # $stdout.print(".");$stdout.flush;
      end
      
      json = JSON.pretty_generate({:entries => index})
      
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
require 'nokogiri'

module Jekyll

  class PageRenderer
    def initialize(site)
      @site = site
    end
    
    # render the item, parse the output and get all text inside <p> elements
    def render(item)
      item.render({}, @site.site_payload)
      doc = Nokogiri::HTML(item.output)
      paragraphs = doc.search('p').map {|e| e.text }
      paragraphs.join(" ").gsub("\r"," ").gsub("\n"," ")
    end
  end
  
end
require 'nokogiri'

module Jekyll
  
  class SearchEntry
    def self.create(page_or_post, renderer)
      return create_from_post(page_or_post, renderer) if page_or_post.is_a?(Jekyll::Post)
      return create_from_page(page_or_post, renderer) if page_or_post.is_a?(Jekyll::Page)
      raise 'Not supported'
    end
    
    def self.create_from_page(page, renderer)
      title, url = extract_title_and_url(page)
      body = renderer.render(page)
      date = nil
      categories = []
      
      SearchEntry.new(title, url, date, categories, body)
    end
    
    def self.create_from_post(post, renderer)
      title, url = extract_title_and_url(post)
      body = renderer.render(post)
      date = post.date
      categories = post.categories
      
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
  end

end
module Jekyll
  
  class SearchIndexFile < StaticFile
    # Override write as the search.json index file has already been created 
    def write(dest)
      true
    end
  end
  
end
