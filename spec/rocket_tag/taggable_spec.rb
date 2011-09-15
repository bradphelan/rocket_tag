require File.expand_path('../../spec_helper', __FILE__)

describe TaggableModel do
  before :each do
    clean_database!
    @model = TaggableModel.create
  end

  it "allows assignment of tags" do
    @model.languages = ["a", "b", "c"]
    @model.reload
    @model.languages.should == ["a", "b", "c"]

    @model.languages = ["x", "y"]
    @model.reload
    @model.languages.should == ["x", "y"]
  end


  it "allows me to get funky with Squeel and ActiveRelation" do

    sql = <<-EOF.gsub(/\s+/, ' ').strip
      SELECT "taggable_models".* 
      FROM "taggable_models" 
      INNER JOIN "taggings" 
        ON "taggings"."taggable_id" = "taggable_models"."id" 
        AND "taggings"."taggable_type" = 'TaggableModel' 
      INNER JOIN "tags" 
        ON "tags"."id" = "taggings"."tag_id" 
        AND taggings.context = 'skills' 
      WHERE 
        "tags"."name" = 'foo'
    EOF

    TaggableModel.joins{skills_tags}.where{skills_tags.name == "foo"}.to_sql.should == sql
  end

  describe "querying tags" do

    before :each do
      @t00 = TaggableModel.create :name => "00"
      @t01 = TaggableModel.create :name => "01"


      @t10 = TaggableModel.create :name => "10"
      @t11 = TaggableModel.create :name => "11"


      @t20 = TaggableModel.create :name => "20"
      @t21 = TaggableModel.create :name => "21"

      @t00.skills = ["a", "b"]
      @t01.skills = ["a", "b"]

      @t10.skills = ["a", "c"]
      @t11.skills = ["a", "c"]

      @t20.skills = ["c", "d"]
      @t21.skills = ["c", "d"]

      @t21.languages = ["german", "jinglish"]
    end

    it "allow me to do eager loading on tags" do
      TaggableModel.all.each do |m|
        puts m.name
        puts m.skills.inspect
        puts m.languages.inspect
        puts m.needs.inspect
        puts "--"
      end
    end

    it "allows to search on tag via active relation" do


      q0 = TaggableModel.tagged_with(["a", "b"], :all => true, :on => :skills ).all
      q0.length.should == 2
      q0.should include @t00
      q0.should include @t01

      q0 = TaggableModel.tagged_with(["a", "b"], :on => :skills ).all
      q0.length.should == 4
      q0.should include @t00
      q0.should include @t01
      q0.should include @t10
      q0.should include @t11

      q0 = TaggableModel.tagged_with(["a", "b"], :on => :languages ).all
      q0.length.should == 0

    end

    it "should eager load the tags" do
    end
  end
end
