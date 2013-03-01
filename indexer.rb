require 'rubygems'
require 'nokogiri'
require 'json'

module Jekyll

  class Indexer < Generator

    def initialize(config = {})
      super(config)
      
      @excludes = [] #config['lunr_excludes'] || []
    end

    # Index all pages except pages matching any value in config['lunr_excludes']
    # The main content from each page is extracted and saved to disk as json
    def generate(site)
      puts 'Indexing pages...'

      # gather pages and posts
      items = pages_to_index(site)
      index = []
      
      items.each do |item|              
        page_text = extract_text(site, item)
        
        index << { 
          :title => item.data['title'] || item.name, 
          :url => item.url,
          :date => item.date,
          :categories => item.categories,
          :body => page_text
        }
        
        puts 'Indexed ' << item.url
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

      puts 'Indexing done'
    end

  private
    
    def pages_to_index(site)
      items = site.pages.dup.concat(site.posts)

      # only process files that will be converted to .html and only non excluded files 
      items = items.find_all {|i| i.output_ext == '.html' && ! @excludes.any? {|s| (i.url =~ Regexp.new(s)) != nil } } 
      # items.reject! {|i| i.data['exclude_from_search'] } 

      # skip index pages
      items.reject! {|i| i.is_a?(Jekyll::Page) && i.index? }
    end
    
    # render the items, parse the output and get all text inside <p> elements
    def extract_text(site, page)
      page.render({}, site.site_payload)
      doc = Nokogiri::HTML(page.output)
      paragraphs = doc.search('p').map {|e| e.text }
      paragraphs.join(" ").gsub("\r"," ").gsub("\n"," ")
    end
  end 
end