require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SynonymFinder" do
  it "should able to ingest input in correct format" do
    sf = SynonymFinder.new(SynonymFinder::Spec::Config.input)
    sf.input.is_a?(Array).should be_true
    sf.input[0].keys.should == [:id, :path, :name]
  end
end
