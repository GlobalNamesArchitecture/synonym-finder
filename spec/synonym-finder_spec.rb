require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SynonymFinder" do
  before(:all) do
    SynonymFinder.logger = Logger.new($stdout)
    @sf = SynonymFinder.new(SynonymFinder::Spec::Config.input)
    # @sf = SynonymFinder.new(open(File.dirname(__FILE__) + "/support/union_data.txt").read)
  end

  it "should able to ingest input in correct format" do
    @sf.input.is_a?(Array).should be_true
    @sf.input[0].keys.should == [:id, :path, :name]
  end

  it "should be able to find species epithet duplications" do
    output = @sf.find_matches
    m = @sf.matches
    m[[1, 100]].should be_nil # 1 name has no auth
    m[[1, 101]].should == {:total_distance=>2, :type=>:homotypic, :auth_match=>100}
    m[[1, 102]].should be_nil # 1 name has no auth
    m[[203, 204]].should == {:total_distance=>0, :type=>:chresonym, :auth_match=>0}
    m[[202, 302]].should == {:total_distance=>2, :type=>:homotypic, :auth_match=>100}
    m[[400, 500]].should == {:total_distance=>4, :type=>:homotypic, :auth_match=>100}
    m[[400, 600]].should == {:total_distance=>4, :type=>:alt_placement, :auth_match=>100}
    m[[400, 700]].should be_nil
    m[[400, 800]].should == {:total_distance=>4, :type=>:homotypic, :auth_match=>100}
    m[[800, 801]].should == {:total_distance=>0, :type=>:misplaced_synonym, :auth_match=>100}
    m[[800, 802]].should == {:total_distance=>0, :type=>:misplaced_synonym, :auth_match=>100}
    m[[800, 803]].should == {:total_distance=>0, :type=>:lexical_variant, :auth_match=>100}
    output.should == [{:type=>"chresonym", :name_ids=>[203, 204]}, {:type=>"alt_placement", :name_ids=>[400, 600]}, {:type=>"chresonym", :name_ids=>[101, 102]}, {:type=>"homotypic", :name_ids=>[203, 303]}, {:type=>"lexical_variant", :name_ids=>[800, 803]}, {:type=>"lexical_variant", :name_ids=>[801, 802]}, {:type=>"homotypic", :name_ids=>[202, 302]}, {:type=>"homotypic", :name_ids=>[1, 101]}, {:type=>"misplaced_synonym", :name_ids=>[801, 803, 802, 800]}]
  end
end
