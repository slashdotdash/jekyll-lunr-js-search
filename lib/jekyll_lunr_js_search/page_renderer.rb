require 'nokogiri'

module Jekyll
  module LunrJsSearch
    class PageRenderer
      def initialize(site)
        @site = site
      end
      
      def prepare(item)
        if item.is_a?(Jekyll::Document)
          Jekyll::Renderer.new(@site, item).run        
        else
          item.data = item.data.dup
          item.data.delete("layout")
          item.render({}, @site.site_payload)
          item.output
        end
      end

      # render the item, parse the output and get all text inside <p> elements
      def render(item)
        layoutless = item.dup

        Nokogiri::HTML(prepare(layoutless)).text
      end
    end
  end  
end