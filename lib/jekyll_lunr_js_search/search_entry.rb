require 'nokogiri'

module Jekyll
  module LunrJsSearch
    class SearchEntry
      def self.create(page_or_post, renderer)
        case page_or_post
        when Jekyll::Page, Jekyll::Document
          if defined?(page_or_post.date)
            date = page_or_post.date
          else
            date = nil
          end
          categories = []
        else 
          if defined?(Jekyll::Post) and page_or_post.is_a?(Jekyll::Post)
            date = page_or_post.date
            categories = page_or_post.categories
          else
            raise 'Not supported'
          end
        end
        title, url = extract_title_and_url(page_or_post)
        body = renderer.render(page_or_post)

        SearchEntry.new(title, url, date, categories, body, renderer)
      end

      def self.extract_title_and_url(item)
        data = item.to_liquid
        [ data['title'], data['url'] ]
      end

      attr_reader :title, :url, :date, :categories, :body, :collection
      
      def initialize(title, url, date, categories, body, collection)
        @title, @url, @date, @categories, @body, @collection = title, url, date, categories, body, collection
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
