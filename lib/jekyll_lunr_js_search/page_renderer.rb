require 'nokogiri'

module Jekyll
  module LunrJsSearch
    class PageRenderer
      def initialize(site)
        @site = site
      end
      
      def site_render(item)
        if item.is_a?(Jekyll::Document)
          item.output = Jekyll::Renderer.new(@site, item).run
        else
          item.render({}, @site.site_payload)
        end
      end

      # render the item, parse the output and get all text inside <p> elements
      def render(item)
        layoutless = item.dup
        layoutless.data = layoutless.data.dup
        layoutless.data.delete('layout')
        site_render(layoutless)
        Nokogiri::HTML(layoutless.output).text
      end
    end
  end  
end