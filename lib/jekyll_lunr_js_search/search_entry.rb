require 'nokogiri'

module Jekyll
  module LunrJsSearch
    class SearchEntry
      def self.create(site, renderer, data_field_names)
        if site.is_a?(Jekyll::Page) or site.is_a?(Jekyll::Document)
          if defined?(site.date)
            date = site.date
          else
            date = nil
          end

          datafields = {}
          data_field_names.each do |fieldname|
            datafields[fieldname] = site.data.has_key? fieldname ? site.data[fieldname] : nil
          end

          title, url = extract_title_and_url(site)
          is_post = site.is_a?(Jekyll::Document)
          body = renderer.render(site)

          SearchEntry.new(title, url, date, is_post, body, datafields, renderer)
        else
          raise 'Not supported'
        end
      end

      def self.extract_title_and_url(item)
        data = item.to_liquid
        [ data['title'], data['url'] ]
      end

      attr_reader :title, :url, :date, :is_post, :body, :datafields, :collection

      def initialize(title, url, date, is_post, body, datafields, collection)
        @title, @url, @date, @is_post, @body, @datafields, @collection = title, url, date, is_post, body, datafields, collection
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

      def get_by_name(field_name)
        case field_name
          when 'title' then @title
          when 'url' then @url
          when 'date' then @date
          when 'is_post' then @is_post
          when 'body' then @body
          else @datafields[field_name]
        end
      end
    end
  end
end
