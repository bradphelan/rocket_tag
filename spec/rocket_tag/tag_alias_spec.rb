require File.expand_path('../../spec_helper', __FILE__)

describe "Tag" do
  before(:all) {
    clean_database!
  }
  describe "#alias methods" do
    before(:each) do
      @a = RocketTag::Tag.create(:name => 'rails')
      @b = RocketTag::Tag.create(:name => 'ror')
      @c = RocketTag::Tag.create(:name => 'ruby-on-rails')
    end

    it "should have alias tags" do
      @a.alias << @b
      @b.alias << @c
      @a.alias.should eq [@b, @c]
      @b.alias.should eq [@a, @c]
      @c.alias.should eq [@a, @b]   
    end
    it "should remove alias if relations delete" do
      @a.alias << @b
      @b.alias << @c
      @a.alias = []
      @a.alias.should eq []
      @b.alias.should eq [@c]
      @c.alias.should eq [@b]
    end
    it "should check if tag is alias" do
      @a.alias << @b
      @a.alias?(@b).should be true
      @b.alias?(@a).should be true
      @c.alias?(@a).should be false
      @c.alias?(@b).should be false
    end
  end
  
  describe "TaggableModel" do
    before(:all) do
      @m1 = TaggableModel.new(:name => 'foo', 
        :skills => ['a', 'b', 'c'])
      @m1.languages =  [ "abc" , "cde"]
      @m1.save
      @m2 = TaggableModel.new(:name => 'bar', 
        :skills => ['d', 'e', 'f'])
      @m2.languages = ["abc"]
      @m2.save
      @m3 = TaggableModel.new(:name => 'baz', 
        :skills => ['b', 'k', 'l'])
      @m3.languages = ["anm"]
      @m3.save
      @m4 = TaggableModel.new(:name => 'zed',
        :skills => ['l', 'z', 'o'])
      @m4.languages = ["tex"]
      @m4.save
      RocketTag::Tag.find_by_name('tex').alias << RocketTag::Tag.find_by_name('abc')
      RocketTag::Tag.find_by_name('a').alias << RocketTag::Tag.find_by_name('d') << RocketTag::Tag.find_by_name('z')
      RocketTag::Tag.find_by_name('e').alias << RocketTag::Tag.find_by_name('k')
    end

    it "should return with alias tags" do
      models = TaggableModel.tagged_with(["a"])
      models.size.should eq (3)
      models.should eq ([@m1, @m2, @m4])
      
      mlangs = TaggableModel.tagged_with(["tex"])
      mlangs.should eq ([@m1, @m2, @m4])

      mall = TaggableModel.tagged_with(:languages => ["tex"], :skills => ["a"])
      mall.should eq ([@m1, @m2, @m4])
      
      TaggableModel.tagged_with(["a", "b", "tex"]).size.should eq(4)
    end
  end  
end
