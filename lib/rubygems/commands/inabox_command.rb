require 'rubygems/command'

class Gem::Commands::InaboxCommand < Gem::Command
  def description
    'Push a gem up to your GemInABox'
  end

  def arguments
    "GEM       built gem to push up"
  end

  def usage
    "#{program_name} GEM"
  end

  def initialize
    super 'inabox', description

    add_option('-c', '--configure', "Configure GemInABox") do |value, options|
      options[:configure] = true
    end

    add_option('-g', '--host HOST', "Host to upload to.") do |value, options|
      options[:host] = value
    end

    add_option('-b', '--bundler', "Install gem from bundler's Gemfile") do |value, options|
      options[:bundler] = true
    end
  end

  def last_minute_requires!
    require 'yaml'
    require File.expand_path("../../../geminabox_client.rb", __FILE__)
    if options[:bundler]
      require 'bundler'
      require File.expand_path("../../../geminabox.rb", __FILE__)
    end
  end

  def execute
    last_minute_requires!
    return configure if options[:configure]
    configure unless geminabox_host

    if options[:args].size == 0
      if options[:bundler]
        bundler = ::Geminabox::Bundler.load_gems
        gemfiles = bundler.fetch_gems
      else
        say "You didn't specify a gem, looking for one in . and in ./pkg/..."
        gemfiles = [GeminaboxClient::GemLocator.find_gem(Dir.pwd)]
      end
    else
      gemfiles = get_all_gem_names
    end

    send_gems(gemfiles)
  end

  def send_gems(gemfiles)
    client = GeminaboxClient.new(geminabox_host)

    gemfiles.each do |gemfile|
      say "Pushing #{File.basename(gemfile)} to #{client.url}..."
      begin
        say client.push(gemfile)
      rescue GeminaboxClient::Error => e
        alert_error e.message
        terminate_interaction(1)
      end
    end
  end

  def config_path
    File.join(Gem.user_home, '.gem', 'geminabox')
  end

  def configure
    say "Enter the root url for your personal geminabox instance. (E.g. http://gems/)"
    host = ask("Host:")
    self.geminabox_host = host
  end

  def geminabox_host
    @geminabox_host ||= options[:host] || Gem.configuration.load_file(config_path)[:host]
  end

  def geminabox_host=(host)
    config = Gem.configuration.load_file(config_path).merge(:host => host)

    dirname = File.dirname(config_path)
    Dir.mkdir(dirname) unless File.exists?(dirname)

    File.open(config_path, 'w') do |f|
      f.write config.to_yaml
    end
  end

  def get_all_gems_from_bundler
    gems = []
    specs = Bunlder.definition.specs
    specs.each do |s|
      gems << [s.name, s.version.to_s]
    end
  end
end
