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

      @t00.skills    =  [ "a"      , "b",  "x"]
      @t00.languages =  [ "german" , "french"]

      @t01.skills    =  [ "a"      , "b", "y"]
      @t01.languages =  [ "german" , "italian"]

      @t10.skills    =  [ "a"      , "c"]
      @t10.languages =  [ "french" , "hebrew"]

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
        it "should count the number of matched tags" do

          #<TaggableModel id: 2, name: "00", type: nil, foo: "A"> - 3 - german, french, a, b, x
          #<TaggableModel id: 3, name: "01", type: nil, foo: "B"> - 3 - german, italian, a, b, y
          #<TaggableModel id: 4, name: "10", type: nil, foo: "A"> - 1 - a, c
          #<TaggableModel id: 5, name: "11", type: nil, foo: "B"> - 1 - a, c
          #<TaggableModel id: 7, name: "21", type: nil, foo: "B"> - 1 - german, jinglish, c, d
          
#           r = TaggableModel.tagged_with(["a", "b", "german"]).all.each do |m|
#             puts "#{m.inspect} - #{m.tags_count} - #{m.tags.map(&:name).join ', '}"
#           end

          r = TaggableModel.tagged_with(["a", "b", "german"]).all
          r.find{|i|i.name == "00"}.tags_count.should == 3
          r.find{|i|i.name == "01"}.tags_count.should == 3
          r.find{|i|i.name == "10"}.tags_count.should == 1
          r.find{|i|i.name == "11"}.tags_count.should == 1
          r.find{|i|i.name == "21"}.tags_count.should == 1

          # The 'group by' operation to generate the count tags should
          # be opaque to downstream operations. Thus count should
          # return the correct number of records
          r = TaggableModel.tagged_with(["a", "b", "german"]).count.should == 5

          # It should be possible to cascade active relation queries on
          # the 
          r = TaggableModel.tagged_with(["a", "b", "german"]).
            where{tags_count>2}.count.should == 2

          # The min option is a shortcut for a query on tags_count
          r = TaggableModel.tagged_with(["a", "b", "german"], :min => 2).count.should == 2

          r = TaggableModel.tagged_with(["a", "b", "german"], :on => :skills).all
          r.find{|i|i.name == "00"}.tags_count.should == 2
          r.find{|i|i.name == "01"}.tags_count.should == 2
          r.find{|i|i.name == "10"}.tags_count.should == 1
          r.find{|i|i.name == "11"}.tags_count.should == 1
          r.find{|i|i.name == "21"}.should be_nil

        end
    end

    describe "#tagged_similar" do
      it "should return similar items" do
        @t00.tagged_similar(:on => :skills).count.should == 3
        @t00.tagged_similar(:on => :languages).count.should == 3
        @t00.tagged_similar.count.should == 4
      end

      it "should return similar items in the correct order with the correct tags_count" do 

        # ----
        similar = @t00.tagged_similar(:on => :skills).all
        similar[0].id.should == @t01.id
        similar[1].id.should == @t10.id
        similar[2].id.should == @t11.id

        similar[0].tags_count.should == 2
        similar[1].tags_count.should == 1
        similar[2].tags_count.should == 1

        # ----
        similar = @t00.tagged_similar(:on => :languages).all
        similar[0].id.should == @t01.id
        similar[1].id.should == @t10.id
        similar[2].id.should == @t21.id

        similar[0].tags_count.should == 1
        similar[1].tags_count.should == 1
        similar[2].tags_count.should == 1

        # ----
        similar = @t00.tagged_similar.all
        similar[0].id.should == @t01.id
        similar[1].id.should == @t10.id
        similar[2].id.should == @t11.id
        similar[3].id.should == @t21.id

        similar[0].tags_count.should == 3
        similar[1].tags_count.should == 2
        similar[2].tags_count.should == 1
        similar[3].tags_count.should == 1
      end

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

      describe "Experiments with AREL" do
        it "foo" do
          u_t = Arel::Table::new :users
          l_t = Arel::Table::new :logs

          counts = l_t.
            group(l_t[:user_id]).
            project(
              l_t[:user_id].as("user_id"), 
              l_t[:user_id].count.as("count_all")
          ).as "foo"

          #puts TaggableModel.joins("JOIN " + counts.to_sql ).to_sql
        end

        it "should" do
          u_t = Arel::Table::new :users
          l_t = Arel::Table::new :logs
	
          counts = l_t.
            group(l_t[:user_id]).
            project(
              l_t[:user_id].as("user_id"), 
              l_t[:user_id].count.as("count_all")
            ).as "foo"
          
          users = u_t.
            join(counts).
            on(u_t[:id].
            eq(counts[:user_id])).
            project("*").project(counts[:count_all])

          # puts users.to_sql
          
        end
      end

      describe "#tagged_with_sifter" do
        it "should be the work horse of #tagged_with but returns a sifter that can be composed into other queries" do
          TaggableModel.where do
            TaggableModel.tagged_with_sifter(["a", "b"]) & TaggableModel.tagged_with_sifter(["c"])
          end.count.should == 2

          x = TaggableModel.where do
            TaggableModel.tagged_with_sifter(["a", "b"]) & TaggableModel.tagged_with_sifter(["c"])
          end.to_sql

          TaggableModel.where do
            TaggableModel.tagged_with_sifter(["a", "b"])
          end.count.should == 4
        end

      end
      
      describe "#popular_tags" do
        it "should return correct list (and correctly ordered) of popular tags for class and context" do
          TaggableModel.popular_tags.all.length.should == RocketTag::Tag.all.count
          TaggableModel.popular_tags.limit(10).all.length.should == 10
          TaggableModel.popular_tags.order('id asc').first.name.should == 'a'
          TaggableModel.popular_tags.order('id asc').last.name.should == 'jinglish'
          TaggableModel.popular_tags(:on=>:skills).order('name asc').first.name.should == 'a'
          TaggableModel.popular_tags(:on=>:skills).order('name asc').last.name.should == 'y'
          TaggableModel.popular_tags(:on=>[:skills, :languages]).order('id asc').first.name.should == 'a'
          TaggableModel.popular_tags(:on=>[:skills, :languages]).order('id asc').last.name.should == 'jinglish'
        end
      end
    end
  end
end

