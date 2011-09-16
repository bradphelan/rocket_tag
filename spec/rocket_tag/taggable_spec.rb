require File.expand_path('../../spec_helper', __FILE__)

describe TaggableModel do
  before :each do
    clean_database!
    @model = TaggableModel.create
  end

  describe "#save" do
    it "persists the tags cache to the database" do
      @model.languages = ["a", "b", "c"]
      @model.save
      @model.reload
      @model.languages.should == ["a", "b", "c"]

      @model.languages = ["x", "y"]
      @model.save
      @model.reload
      @model.languages.should == ["x", "y"]
    end
  end
  describe "#reload" do
    it "resets the tags caches to what is in the database" do
      @model.languages = ["a", "b", "c"]
      @model.reload
      @model.languages.should == []

      @model.languages = ["x", "y"]
      @model.reload
      @model.languages.should == []

      @model.needs = ["a"]
      @model.save
      @model.reload
      @model.needs.should == ["a"]
      @model.needs = ["b"]
      @model.needs.should == ["b"]
      @model.reload
      @model.needs.should == ["a"]
    end
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

      @t00.skills    =  [ "a"      , "b"]
      @t00.languages =  [ "german" , "french"]

      @t01.skills    =  [ "a"      , "b"]
      @t01.languages =  [ "german" , "italian"]

      @t10.skills    =  [ "a"      , "c"]

      @t11.skills    =  [ "a"      , "c"]

      @t20.skills    =  [ "c"      , "d"]

      @t21.skills    =  [ "c"      , "d"]

      @t21.languages =  [ "german" , "jinglish"]

      @t00.save
      @t01.save
      @t10.save
      @t11.save
      @t20.save
      @t21.save
    end

    it "allow me to do eager loading on tags" do
      pending "Need to figure out how to verify eager loading other than manually inspect the log file"
    end

    describe "#tagged_with" do
      describe ":all => true" do
        it "should return records where *all* tags match on any context" do
          q0 = TaggableModel.tagged_with(["a", "german"], :all => true ).all
          q0.length.should == 2
          q0.should include @t00
          q0.should include @t01
        end
      end
      describe ":all => false" do
        it "should return records where *any* tags match on any context" do
          q0 = TaggableModel.tagged_with(["a", "german"] ).all
          q0.length.should == 5
          q0.should include @t00
          q0.should include @t01
          q0.should include @t10
          q0.should include @t11
          q0.should include @t21

          q0.should_not include @t20 # as it has neither "a" nor "german" tagged
                                     # on any context
        end
      end

      describe ":all => false, :on => context" do
        it "should return records where *any* tags match on the specific context" do
          q0 = TaggableModel.tagged_with(["a", "german"], :on => :skills ).all
          q0.length.should == 4
          q0.should include @t00
          q0.should include @t01
          q0.should include @t10
          q0.should include @t11

          q0.should_not include @t21
          q0.should_not include @t20
        end
      end

      describe ":all => true, :on => context" do
        it "should return records where *all* tags match on the specific context" do
          q0 = TaggableModel.tagged_with(["a", "german"], :on => :skills, :all => true ).all
          q0.length.should == 0

          q0 = TaggableModel.tagged_with(["a", "b"], :on => :skills, :all => true ).all
          q0.length.should == 2
          q0.should include @t00
          q0.should include @t01
        end
      end
    end
  end
end
