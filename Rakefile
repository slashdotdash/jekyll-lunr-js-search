require 'rake'
require 'uglifier'

task :default => :build

task :build => [:create_build_dir, :copy_jekyll_plugin, :concat_js, :minify_js] do
end

task :create_build_dir do
	Dir.mkdir('build') unless Dir.exists?('build')
end

task :copy_jekyll_plugin do
	system('ls lib/jekyll_lunr_js_search/*.rb | while read file; do cat $file; echo ""; done > build/jekyll_lunr_js_search.rb')
end

task :concat_js do
    out = ''
    files = [
    	'bower_components/jquery/dist/jquery.js',
    	'bower_components/lunr.js/lunr.js',
    	'bower_components/mustache/mustache.js',
    	'bower_components/date.format/index.js',
    	'bower_components/uri.js/src/URI.js',
    	'js/jquery.lunr.search.js'
    ]

    files.each do |file|
    	out += File.read(file)
    end
 
    File.open('build/search.min.js', 'w') do |file|
		file.write(out)
    end
end

task :minify_js do
    minified = Uglifier.compile(File.read('build/search.min.js'))
    File.open('build/search.min.js', 'w') { |file| file.write(minified) }
end