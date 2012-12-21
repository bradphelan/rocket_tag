Rocket Tag
==========

Clean, modern and maintainable, context aware tagging library for rails 3.1 +

Installation
------------

In your gemfile

	gem "rocket_tag"

Then at the command line
	
	bundle install

Create the migration at the command line

	rails generate rocket_tag:migration
	rake db:migrate
	rake db:test:prepare

Configuration
-------------

Add configurations to `config/initializers/rocket_tag.rb`:

```ruby
RocketTag.configure do |config|
  config.force_lowercase = true # Automatically convert all tags to lowercase (optional, default: false)
end
```

Usage
-----

	class TaggableModel < ActiveRecord::Base
		attr_taggable :skills, :habits
	end	

	item = TaggableModel.create

	item.skills = ["kiting", "surfing", "coding"]
	item.habits = ["forking", "talking"]


Match any tag across any contexts

    TaggableModel.tagged_with ["forking", "kiting"]  

Match all tags across any contexts

    TaggableModel.tagged_with ["forking", "kiting"], :all => true

Match any tag on a specific context

    TaggableModel.tagged_with ["math", "kiting"], :on => "skills"

Match all tags on a specific context

    TaggableModel.tagged_with ["math", "kiting"], :all => true, :on => "skills"
	
Match a miniumum number of tags

    TaggableModel.tagged_with ["math", "kiting", "coding", "sleeping"], :min => 2, :on => "skills"

Match tags to specific contexts

    TaggableModel.tagged_with { :skills => ["math", "kiting"], :languages => ["english", "german"]
	
Take advantage of the tags_count synthetic column returned with every query

    TaggableModel.tagged_with(["math", "kiting", "coding", "sleeping"], :on => "skills").where{tags_count>=2}	

Mix with active relation 

    TaggableModel.tagged_with(["forking", "kiting"]).where( ["created_at > ?", Time.zone.now.ago(5.hours)])  

or even downstream

    User.where{email="bradphelan@xtargets.com"}.documents.tagged_with ['kiting', 'math'] , :on => :skills

where we might have

    class User < ActiveRecord::Base
      has_many :documents
    end

    class Document < ActiveRecord::Base
      belongs_to :user
      attr_taggable :tags
    end 

Find similar models based on tags on a specific context and return in decending order
of 'tags_count'

    model.tagged_similar :on => "skills"
    model.tagged_similar :on => "habits"

The two cases of tagged_similar below are functionally identical because there are
only two contexts specified on the class. If there were three or more contexts specified
then the two below would not be identical.

    model.tagged_similar :on => ["skills", "habits"]
    model.tagged_similar

Find popular tags and generate tags clouds for specific scopes

    User.where{email="bradphelan@xtargets.com"}.documents.popular_tags

where we might have

    class User < ActiveRecord::Base
      has_many :documents
    end

    class Document < ActiveRecord::Base
      belongs_to :user
      attr_taggable :tags
    end 

and you can access the field *tags_count* on each Tag instance returned
by the above query. Generating the CSS and html for your tag cloud
is outside the scope of this project but it should be easy to do.

Alias tags. 
If you have several tags that means the same things, then create alias for it.
    
    #array with inctances of RocketTag::Tag
    tag1, tag2, tag3 = ['ror', 'ruby-on-rails', 'rails'] 
    tag1.alias << [tag2, tag3]
    #Models with tag `rails`
    # returns all Posts with `rails`, `ruby-on-rails` and `ror` tags 
    Post.tagged_with(['rails']) 




Contributing to rocket_tag
--------------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2011 Brad Phelan. See LICENSE.txt for
further details.

Available for hire for your next ROR project at <a href="http://xtargets.com" title="XTargets: Ruby On Rails Solutions" rel="author">XTargets: Ruby On Rails Solutions</a>

