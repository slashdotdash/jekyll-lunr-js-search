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