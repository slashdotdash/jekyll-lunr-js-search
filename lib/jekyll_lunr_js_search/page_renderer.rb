require 'nokogiri'

module Jekyll
  module LunrJsSearch
    class PageRenderer
      def initialize(site)
        @site = site
      end
      
      # render the item, parse the output and get all text inside <p> elements
      def render(item)
        item.render({}, @site.site_payload)
        Nokogiri::HTML(item.output).text
      end
    end
  end  
end