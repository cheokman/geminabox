require 'pathname'
require 'tempfile'

class GemFileFactory
  DEFAULT_GEMS = [{:name => "rails", :version => "3.2.4"},{:name => "bundler"}]
  def initialize()
    @path = Dir.tmpdir
    @dest_file_name = File.join(@path, "Gemfile")
  end

  def gem_file(options=[])
    gem_files = options.map do |e|
      gem_config = "gem \'#{e[:name]}\'"
      version = (e[:version] || "0").split(".").map { |v| v.to_i }.select { |v| v > 0 }
      gem_config << ", \'#{e[:version]}\'" unless version.empty? 
      gem_config
    end.join("\n")

    File.open(@dest_file_name,'w') do |g|
      g << gem_files
    end
    @path
  end

  class << self
    def default_gem_file(gem_list = nil)
      gem_list ||= DEFAULT_GEMS 
      GemFileFactory.new.gem_file(gem_list)
    end
  end
end