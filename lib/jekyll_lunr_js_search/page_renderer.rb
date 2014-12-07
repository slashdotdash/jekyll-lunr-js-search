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