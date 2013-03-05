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