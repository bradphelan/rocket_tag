require File.expand_path('../../spec_helper', __FILE__)

describe TaggableModel do
  before :each do
    clean_database!
    @model = TaggableModel.create
  end

  describe "parsing" do
      it "converts strings to arrays using ruby core lib CSV" do
          m = TaggableModel.new :skills => %q%hello, is it me, you are looking for, cat%
          m.skills.should == ["hello", "is it me", "you are looking for", "cat"]

          m = TaggableModel.new :skills => %q%hello, "is it me, you are looking for", cat%
          m.skills.should == ["hello", "is it me, you are looking for", "cat"]
      end
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

    it "validates the model wrt to the context" do
      @model.languages = 100
      @model.save.should == false
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

    sql = <<-EOF.gsub(/\s+/, ' ').strip
        SELECT distinct taggable_models.* 
        FROM "taggable_models" 
        INNER JOIN "taggings" 
        ON 
          "taggings"."taggable_id" = "taggable_models"."id" 
        AND 
          "taggings"."taggable_type" = 'TaggableModel' 
        INNER JOIN "tags" 
        ON 
          "tags"."id" = "taggings"."tag_id" 
        WHERE 
          "taggable_models"."id" IN 
            (SELECT "taggable_models"."id" 
              FROM "taggable_models" 
              INNER JOIN "taggings" 
              ON "taggings"."taggable_id" = "taggable_models"."id" 
              AND "taggings"."taggable_type" = 'TaggableModel' 
              INNER JOIN "tags" 
              ON "tags"."id" = "taggings"."tag_id" WHERE "tags"."name" 
              IN ('a', 'b') 
              GROUP BY "taggable_models"."id" 
              HAVING count("taggable_models"."id") = 2) 
          AND 
            (created_at > '2011-09-16 05:41')
       EOF
    
    TaggableModel.tagged_with(["a", "b"], :all =>true).where(["created_at > ?", "2011-09-16 05:41"]).to_sql.should == sql
  end


  describe "combining with active relation" do
    before :each do
      TaggableModel.create :name => "test 0", :needs => %w[x y z]
      TaggableModel.create :name => "test 1", :needs => %w[a b c]
      TaggableModel.create :name => "test 2", :needs => %w[a b c]
      TaggableModel.create :name => "test 3", :needs => %w[a b c]

      TaggableModel.create :name => "app  0", :skills => %w[x y z]
      TaggableModel.create :name => "app  1", :skills => %w[a b c]
      TaggableModel.create :name => "app  2", :skills => %w[a b c]
      TaggableModel.create :name => "app  3", :skills => %w[a b c]
    end

    it "should generate the correct results" do

      TaggableModel.tagged_with(%w[a b], :all=>true).count(:distinct => true).should == 6
      TaggableModel.tagged_with(%w[a b], :all=>true).where{name.like "app%"}.count(:distinct => true).should == 3

      TaggableModel.tagged_with(%w[a b], :all=>true).where{name.like "%1"}.count(:distinct => true).should == 2
      TaggableModel.tagged_with(%w[a b], :all=>true, :on => :skills).where{name.like "%1"}.count(:distinct => true).should == 1

    end
  end
  describe "querying tags" do

    before :each do
      @t00 = TaggableModel.create :name => "00", :foo => "A"
      @t01 = TaggableModel.create :name => "01", :foo => "B"


      @t10 = TaggableModel.create :name => "10", :foo => "A"
      @t11 = TaggableModel.create :name => "11", :foo => "B"


      @t20 = TaggableModel.create :name => "20", :foo => "A"
      @t21 = TaggableModel.create :name => "21", :foo => "B"

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
          q0 = TaggableModel.tagged_with(["a", "german"], :on => :skills, :all => true )
          q0.all.length.should == 0

          q0 = TaggableModel.tagged_with(["a", "b"], :on => :skills, :all => true ).all
          q0.length.should == 2
          q0.should include @t00
          q0.should include @t01

          q0 = TaggableModel.tagged_with(["a", "b"], :on => :skills, :all => true ).where{foo=="A"}.all
          q0.length.should == 1
          q0.should include @t00
          q0.should_not include @t01
        end
      end
    end
  end
end
