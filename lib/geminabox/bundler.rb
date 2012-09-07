require "bundler"
require "rubygems/dependency_installer"
require 'pathname'
require 'tempfile'

class Geminabox
  class Bundler
    attr_reader :gemfile, :gem_requirements, :gems, :gem_path
    def initialize(gem_file)
      @gem_file = gem_file
      @gem_requirements = nil
      @gems = []
      @gem_path = Dir.tmpdir
    end
    
    def load_gem_file
      if compare_version("1.2.0") == -1
        @gem_requirements = ::Bundler::Dsl.new.instance_eval(::Bundler.read_file(@gem_file)) 
      else
        @gem_requirements = ::Bundler::Dsl.new.eval_gemfile(@gem_file)
      end
    end

    def compare_version(version)
      current = ::Bundler::VERSION.split(".").map { |e| e.to_i }
      required_version = version.split(".").map { |e| e.to_i }

      return current <=> required_version
    end

    def load_gems
      @gem_requirements ||= load_gem_file
      @gem_requirements.each do |g|
        @gems << {:name => gem_name(g), :version => gem_version(g)}
      end
    end

    def fetch_gems
      @inst ||= Gem::DependencyInstaller.new
      fetched_gems = []
      @gems.each do |g|
        fetched_gems << fetch_gem(g[:name], g[:version])
      end
      fetched_gems
    end

private
    def fetch_gem(gem_file_name,version=nil)
      #conver version = 0 case to nil
      version = version.to_i == 0 ? nil : version
      
      spec = @inst.find_spec_by_name_and_version gem_file_name, version
      gem_file_name =  gem_full_name(spec)

      # if local cache, use cached gem instead 
      return File.join(bundler_gem_path,gem_file_name) if local_cache?(gem_file_name)

      # if not local cache, download from Internet
      source_uri = gem_source_uri(spec)
      dest_filename = File.join(@gem_path, gem_file_name)

      remote_gem_path = source_uri + "gems/#{gem_file_name}"

      gem = Gem::RemoteFetcher.fetcher.fetch_path remote_gem_path

      File.open dest_filename, 'wb' do |fp|
        fp.write gem
      end
      dest_filename
    end

    def local_cache?(gem_file_name)
      File.exist?(File.join(bundler_gem_path,gem_file_name))
    end

    def bundler_gem_path
      "#{::Bundler.rubygems.gem_dir}/cache"
    end

    def gem_version(_gem)
      _gem.requirement.requirements[0][1].version
    end

    def gem_full_name(spec)
      spec[0][0].file_name
    end

    def gem_source_uri(spec)
      spec[0][1]
    end

    def gem_name(_gem)
      _gem.name
    end

    class << self
      def load_gems(gem_file_path = File.expand_path('.'))
        @bundler = new(File.join(gem_file_path,"Gemfile"))
        @bundler.load_gems
        @bundler
      end
    end
  end
end