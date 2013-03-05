require 'rubygems'
require 'json'

module Jekyll

  class Indexer < Generator

    def initialize(config = {})
      super(config)
      
      @excludes = config['lunr_excludes'] || []
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

        index << {
          :title => entry.title, 
          :url => entry.url,
          :date => entry.date,
          :categories => entry.categories,
          :body => entry.body
        }
        
        puts 'Indexed ' << entry.url        
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
      items = site.pages.dup.concat(site.posts)

      # only process files that will be converted to .html and only non excluded files 
      items = items.find_all {|i| i.output_ext == '.html' && ! @excludes.any? {|s| (i.url =~ Regexp.new(s)) != nil } } 
      items.reject! {|i| i.data['exclude_from_search'] } 
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
      title = extract_title(page)
      
      url = "#{page.instance_variable_get('@dir')}"
      url = "#{url}/" if page.index?
      url = File.join(url, page.dir) unless page.index?

      body = renderer.render(page)
      date = nil
      categories = []
      
      SearchEntry.new(title, url, date, categories, body)
    end
    
    def self.create_from_post(post, renderer)
      title = extract_title(post)
      url = post.url
      body = renderer.render(post)
      date = post.date
      categories = post.categories
      
      SearchEntry.new(title, url, date, categories, body)
    end
    
    def self.extract_title(item)
      item.data['title'] || item.name
    end

    attr_reader :title, :url, :date, :categories, :body
    
    def initialize(title, url, date, categories, body)
      @title, @url, @date, @categories, @body = title, url, date, categories, body
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
