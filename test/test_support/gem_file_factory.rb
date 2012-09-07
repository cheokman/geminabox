require 'pathname'
require 'tempfile'

class GemFileFactory
  def initialize()
    @path = File.join(Dir.tmpdir, "Gemfile")
  end

  def gem_file(options=[])
    gem_files = options.each do |e|
      gem_config = "gem \'#{e[:name]}\'"
      version = e[:version].split("x").map { |v| v.to_i }.select { |v| v > 0 }
      gem_config << " \'#{e[:version]}\'" unless version.empty? 
      puts "*" * 80
      puts ">>> #{gem_config}"
    end.join("\n")
puts gem_files
    File.open(@path,'w') do |g|
      g << gem_files
    end
    @path
  end

  class << self
    def default_gem_file
      gem_list = [{:name => "rails", :version => "3.2.4"}, {:name => "bundler"}]
      GemFileFactory.new.gem_file(gem_list)
    end
  end
end