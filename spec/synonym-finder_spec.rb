require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SynonymFinder" do
  before(:all) do
    @sf = SynonymFinder.new(SynonymFinder::Spec::Config.input)
  end

  it "should able to ingest input in correct format" do
    @sf.input.is_a?(Array).should be_true
    @sf.input[0].keys.should == [:id, :path, :name]
  end

  it "should be able to find species epithet duplications" do
    res = @sf.find_matches
    require 'ruby-debug'; debugger
    puts ''
  end
end
