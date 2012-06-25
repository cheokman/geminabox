class Geminabox::DependencyFetcher

  class << self 
    @specs_and_sources = []
    @inst = nil
    @path = nil

    def find_dependencies to_do, dependency_list 
      seen = {}

      dependencies = Hash.new { |h, name| h[name] = Gem::Dependency.new name }

      until to_do.empty? do
        spec = to_do.shift
        next if spec.nil? or seen[spec.name]
        seen[spec.name] = true

        deps = spec.runtime_dependencies
        deps |= spec.development_dependencies if @development

        deps.each do |dep|
          dependencies[dep.name] = dependencies[dep.name].merge dep

          results = @inst.find_gems_with_sources(dep).reverse

          results.reject! do |dep_spec,|
            to_do.push dep_spec
            Gem::Specification.any? do |installed_spec|
               dep.name == installed_spec.name and
               dep.requirement.satisfied_by? installed_spec.version
             end
          end

          results.each do |dep_spec, source_uri|
            @specs_and_sources << [dep_spec, source_uri]

            dependency_list.add dep_spec
          end
        end
      end

      dependency_list.remove_specs_unsatisfied_by dependencies
      dependency_list
    end

    def specs_and_sources
      @specs_and_sources
    end

    def reset_gem_spec
      Gem.post_reset{ Gem::Specification.all = nil}
      @indexer = Gem::Indexer.new(@path)
      @indexer.generate_index
    end

    def fetch path, gem_name, version=nil
      gem_name, version = split_gem_name gem_name if version.nil?
      return nil if gem_name.nil? || version.nil?

      @path = path

      #
      # Reset Gem Path to default current gem path
      #
      reset_gem_spec

      @inst = Gem::DependencyInstaller.new

      @specs_and_sources = @inst.find_spec_by_name_and_version gem_name, version

      spec = @specs_and_sources.map {|spec, _| spec}

      dep = Gem::DependencyList.new

      to_do = spec.dup

      find_dependencies to_do, dep

      dep.each do |d|
        _, source_uri = @specs_and_sources.assoc d
        gem_file_name = File.basename d.cache_file

        remote_gem_path = source_uri + "gems/#{gem_file_name}"

        dest_filename = File.join(@path, "gems", gem_file_name)

        gem = Gem::RemoteFetcher.fetcher.fetch_path remote_gem_path 

        File.open dest_filename, 'wb' do |fp|
          fp.write gem
        end
      end

      reset_gem_spec unless dep.specs.empty?
    end

    def split_gem_name gem_file_name
      regexp_matcher = %r{(.*)-(#{Gem::Version::VERSION_PATTERN})\.gem}
      result = gem_file_name.match regexp_matcher
      return [nil,nil] unless result 
      [result[1], result[2]]
    end

  end
end
