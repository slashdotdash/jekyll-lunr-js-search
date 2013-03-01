module Jekyll
  
  class SearchIndexFile < StaticFile
    # Override write as the search.json index file has already been created 
    def write(dest)
      true
    end
  end
  
end