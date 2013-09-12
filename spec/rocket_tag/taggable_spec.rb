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

    it "parses an empty string to an empty array" do
      m = TaggableModel.new :skills => ""
      m.skills.should == []
    end
  end

  context 'converting tags to lowercase' do
    let(:tags) { ['Foo', 'BAR', 'bAZ'] }

    context 'when force_lowercase is set to true' do
      before do
        RocketTag.configure do |config|
          config.force_lowercase = true
        end
      end

      it 'should convert the tags as lowercase' do
        expect do
          @model.languages = ['Foo', 'BAR', 'bAZ']
        end.to change { @model.languages }.to(tags.map(&:downcase))
      end
    end

    context 'when force_lowercase is set to false' do
      before do
        RocketTag.configure do |config|
          config.force_lowercase = false
        end
      end

      it 'should convert the tags as lowercase' do
        expect do
          @model.languages = ['Foo', 'BAR', 'bAZ']
        end.to change { @model.languages }.to(tags)
      end
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
      @model.languages.sort.should == ["x", "y"]
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
      TaggableModel.tagged_with(%w[a b], :all=>true).distinct.count.should == 6
      TaggableModel.tagged_with(%w[a b], :all=>true).where{name.like "app%"}.distinct.count.should == 3
      TaggableModel.tagged_with(%w[a b], :all=>true).where{name.like "%1"}.distinct.count.should == 2
      TaggableModel.tagged_with(%w[a b], :all=>true, :on => :skills).where{name.like "%1"}.distinct.count.should == 1
    end
  end

  describe "querying tags" do
    before :each do
      @user0 = User.create :name => "brad"
      @user1 = User.create :name => "hannah"

      @t00 = TaggableModel.create :name => "00", :foo => "A", :user => @user0
      @t01 = TaggableModel.create :name => "01", :foo => "B", :user => @user1


      @t10 = TaggableModel.create :name => "10", :foo => "A", :user => @user0
      @t11 = TaggableModel.create :name => "11", :foo => "B", :user => @user1


      @t20 = TaggableModel.create :name => "20", :foo => "A", :user => @user0
      @t21 = TaggableModel.create :name => "21", :foo => "B", :user => @user1

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

    describe "#tagged_similar" do
      it "should return similar items" do
        @t00.tagged_similar(:on => :skills).count.should == 3
        @t00.tagged_similar(:on => :languages).count.should == 3

        @t00.tagged_similar(:on => [:languages, :skills]).count.should == 4

        # Effectively similar to specifying all the contexts in
        # the on clause
        @t00.tagged_similar.count.should == 4
      end

      it "should return similar items in the correct order with the correct tags_count" do
        # ----
        similar = @t00.tagged_similar(:on => :skills).to_a
        similar[0].id.should == @t01.id
        similar[1].id.should == @t10.id
        similar[2].id.should == @t11.id

        similar[0].tags_count.should == 2
        similar[1].tags_count.should == 1
        similar[2].tags_count.should == 1

        # ----
        similar = @t00.tagged_similar(:on => :languages).to_a.sort
        similar[0].id.should == @t01.id
        similar[1].id.should == @t10.id
        similar[2].id.should == @t21.id

        similar[0].tags_count.should == 1
        similar[1].tags_count.should == 1
        similar[2].tags_count.should == 1

        # ----
        similar = @t00.tagged_similar.to_a
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
      it "should count the number of matched tags" do
        r = TaggableModel.tagged_with(["a", "b", "german"]).to_a
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

        r = TaggableModel.tagged_with(["a", "b", "german"], :on => :skills).to_a
        r.find{|i|i.name == "00"}.tags_count.should == 2
        r.find{|i|i.name == "01"}.tags_count.should == 2
        r.find{|i|i.name == "10"}.tags_count.should == 1
        r.find{|i|i.name == "11"}.tags_count.should == 1
        r.find{|i|i.name == "21"}.should be_nil

        # It should be possible to narrow scopes with tagged_with
        r = @user0.taggable_models.tagged_with(["a", "b", "german"], :on => :skills).to_a
        r.find{|i|i.name == "00"}.tags_count.should == 2
        r.find{|i|i.name == "01"}.should be_nil
        r.find{|i|i.name == "10"}.tags_count.should == 1
        r.find{|i|i.name == "11"}.should be_nil
        r.find{|i|i.name == "21"}.should be_nil
      end

      describe ":all => true" do
        it "should return records where *all* tags match on any context" do
          q0 = TaggableModel.tagged_with(["a", "german"], :all => true ).to_a
          q0.length.should == 2
          q0.should include @t00
          q0.should include @t01
        end
      end

      describe ":all => false" do
        it "should return records where *any* tags match on any context" do
          q0 = TaggableModel.tagged_with(["a", "german"] ).to_a
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
          q0 = TaggableModel.tagged_with(["a", "german"], :on => :skills ).to_a
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
          q0.to_a.length.should == 0

          q0 = TaggableModel.tagged_with(["a", "b"], :on => :skills, :all => true ).to_a
          q0.length.should == 2
          q0.should include @t00
          q0.should include @t01

          q0 = TaggableModel.tagged_with(["a", "b"], :on => :skills, :all => true ).where{foo=="A"}.to_a
          q0.length.should == 1
          q0.should include @t00
          q0.should_not include @t01
        end
      end

      describe 'exact parameter' do
        let(:exact_tags) { ['foo', 'bar'] }

        describe ':exact => true' do
          let(:foo_model)         { TaggableModel.create(:skills => ['foo']) }
          let(:foo_bar_model)     { TaggableModel.create(:skills => ['foo', 'bar']) }
          let(:foo_bar_baz_model) { TaggableModel.create(:skills => ['foo', 'bar', 'baz']) }

          it 'should not return records that are missing any of the speficied tags' do
            TaggableModel.tagged_with(exact_tags, :exact => true).should_not include(foo_model)
          end

          it 'should not return records that have more than the specified tags' do
            TaggableModel.tagged_with(exact_tags, :exact => true).should_not include(foo_bar_baz_model)
          end

          it 'should return records that have exactly the specificed tags' do
            TaggableModel.tagged_with(exact_tags, :exact => true).should include(foo_bar_model)
          end
        end

        describe ':exact => true, :on => context' do
          let(:skills_foo_model)            { TaggableModel.create(:skills => ['foo']) }
          let(:skills_foo_bar_model)        { TaggableModel.create(:skills => ['foo', 'bar']) }
          let(:skills_foo_bar_baz_model)    { TaggableModel.create(:skills => ['foo', 'bar', 'baz']) }
          let(:languages_foo_model)         { TaggableModel.create(:languages => ['foo']) }
          let(:languages_foo_bar_model)     { TaggableModel.create(:languages => ['foo', 'bar']) }
          let(:languages_foo_bar_baz_model) { TaggableModel.create(:languages => ['foo', 'bar', 'baz']) }

          context 'with the correct context' do
            let(:context) { :skills }

            it 'should not return any records with incorrect context' do
              [languages_foo_model, languages_foo_bar_model, languages_foo_bar_baz_model].each do |model|
                TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should_not include(model)
              end
            end

            it 'should not return records with correct context that are missing any of the speficied tags' do
              TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should_not include(skills_foo_model)
            end

            it 'should not return records with correct context that have more than the specified tags' do
              TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should_not include(skills_foo_bar_baz_model)
            end

            it 'should return records with correct context that have exactly the specificed tags' do
              TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should include(skills_foo_bar_model)
            end
          end

          context 'with the incorrect context' do
            let(:context) { :languages }

            it 'should not return any records with incorrect context' do
              [skills_foo_model, skills_foo_bar_model, skills_foo_bar_baz_model].each do |model|
                TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should_not include(model)
              end
            end

            it 'should not return records with correct context that are missing any of the speficied tags' do
              TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should_not include(languages_foo_model)
            end

            it 'should not return records with correct context that have more than the specified tags' do
              TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should_not include(languages_foo_bar_baz_model)
            end

            it 'should return records with correct context that have exactly the specificed tags' do
              TaggableModel.tagged_with(exact_tags, :exact => true, :on => context).should include(languages_foo_bar_model)
            end
          end
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
        end
      end

      describe "Using in subqueries" do
        it "should be possible to select the 'id' of the relation to use in a subquery" do
          q = TaggableModel.where do
            id.in(TaggableModel.tagged_with(["a", "b"]).select{id}) &
            id.in(TaggableModel.tagged_with(["c"]).select{id})
          end
          q.count.should == 2

          TaggableModel.where do
            id.in(TaggableModel.tagged_with(["a", "b"]).select{id})
          end.count.should == 4
        end
      end

      describe "#popular_tags" do
        it "should return correct list (and correctly ordered) of popular tags for class and context" do
          TaggableModel.popular_tags.to_a.length.should == RocketTag::Tag.all.count
          TaggableModel.popular_tags.limit(10).to_a.length.should == 10
          TaggableModel.popular_tags.order('tags_count desc, name desc').first.name.should == 'c'
          TaggableModel.popular_tags.order('id asc').first.name.should == 'a'
          TaggableModel.popular_tags.order('id asc').last.name.should == 'jinglish'
          TaggableModel.popular_tags(:on=>:skills).order('name asc').first.name.should == 'a'
          TaggableModel.popular_tags(:on=>:skills).order('name asc').last.name.should == 'y'
          TaggableModel.popular_tags(:on=>[:skills, :languages]).order('id asc').first.name.should == 'a'
          TaggableModel.popular_tags(:on=>[:skills, :languages]).order('id asc').last.name.should == 'jinglish'
          TaggableModel.popular_tags(:min=>2).to_a.length.should == 6 ## dirty!
        end
      end

      describe "tag cloud calculations" do
        it "should return tags on an association and the counts thereof" do
          # Check that the tags_count on each tag is in
          # descending order.
          @user0.taggable_models.popular_tags.count.should == 8
          @user0.taggable_models.popular_tags.inject do |s, t|
            s.tags_count.should >= t.tags_count
            t
          end

          @user1.taggable_models.popular_tags.count.should == 8
          @user1.taggable_models.popular_tags.inject do |s, t|
            s.tags_count.should >= t.tags_count
            t
          end

          # Sanity check the two queries are not identical
          @user0.taggable_models.popular_tags.should_not ==
            @user1.taggable_models.popular_tags
        end
      end

      describe 'converting tags to lowercase' do
        before do
          RocketTag.configure do |config|
            config.force_lowercase = true
          end
        end

        let(:tags) { ['Foo', 'BAR', 'bAZ'] }
        subject { TaggableModel.create :skills => tags.map(&:downcase) }

        it 'should find the tags in lowercase' do
          TaggableModel.tagged_with(tags, :on => :skills).should eq([subject])
        end
      end
    end
  end
end
