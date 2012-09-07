require "minitest/spec"
require 'minitest/autorun'
require File.expand_path(File.join(File.dirname(__FILE__),"gem_file_factory"))
require File.expand_path(File.join(File.dirname(__FILE__), "../lib/geminabox"))

describe Geminabox::Bundler do
  before do
    @gem_file = GemFileFactory.default_gem_file
    @bundler = Geminabox::Bundler.load_gems(@gem_file)
    @default_gems = GemFileFactory::DEFAULT_GEMS 
  end

  describe "when load gem file" do
    it "should have load gems" do
      @bundler.gems.size.must_equal 2
      @bundler.gems[0][:name].must_be :==, @default_gems[0][:name]
      @bundler.gems[0][:version].must_be :==, @default_gems[0][:version]
    end

    it "should download gems" do
      fetched_gems = @bundler.fetch_gems
      fetched_gems.size.must_equal 2
    end
  end	
end