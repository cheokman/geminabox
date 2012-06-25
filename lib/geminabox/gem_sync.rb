require 'httparty'

class Geminabox::GemSync
  include HTTParty

  RUBY = 'ruby'
  SPECS_FILE_Z = "specs.#{Gem.marshal_version}.gz"

  def initialize(path, remote_uri)
   @uri = remote_uri 
   @path = path
   @client = GeminaboxClient.new(@uri)
   self.class.base_uri @uri
  end

  #
  # TODO: Replace HTTParty with URI lib
  #

  def remote_spec
   self.class.get "/#{SPECS_FILE_Z}"
  end

  def remote_gems
    if remote_spec.response.code.to_i == 200 
      @remote_gems ||= load_gems(remote_spec)
    end

    @remote_gems ||= []
  end

  def load_gems(data)
    gems = Marshal.load(Gem.gunzip(data))

    gems.map! do |name, ver, plat|
            # If the platform is ruby, it is not in the gem name
      "#{name}-#{ver}#{"-#{plat}" unless plat == RUBY}.gem"
    end
    gems
  end

  def existing_gems
    @existing_gems ||= load_gems(File.open(File.join(@path, SPECS_FILE_Z), 'r').read)
  end

  def gems_to_push
    existing_gems - remote_gems
  end

  def gems_to_delete
    remote_gems - existing_gems
  end

  def scan_gems
    @gems_to_push = gems_to_push
    @gems_to_delete = gems_to_delete
  end

  def push_gems
    @gems_to_push.each do |gem|
      gem_file = File.join(@path,"gems",gem)
      @client.push(gem_file)
    end
  end 

  #
  # TODO add delete gems feature in Geminabox
  #
  def cleanup_gems 
    
  end

  def sync
    scan_gems
    push_gems
    cleanup_gems
  end
end
