module Jekyll
  module LunrJsSearch  
	  class SearchIndexFile < Jekyll::StaticFile
	    # Override write as the search.json index file has already been created 
	    def write(dest)
	      true
	    end
	  end
  end
end