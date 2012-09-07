class Geminabox::Bundler
	def initialize(path)
		@path = path
	end
	
	def tmp
		Bundler.tmp
	end
	
end