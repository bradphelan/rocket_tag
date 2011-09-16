Rocket Tag
==========

Clean, modern an maintainable, context aware tagging library for rails 3.1 +

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

Usage
-----

	class TaggableModel < ActiveRecord::Base
		attr_taggable :skills, :habits
	end	

	item = TaggableModel.create

	item.skills = ["kiting", "surfing", "coding"]
	item.habits = ["forking", "talking"]


	# Match any tag across any contexts
	TaggableModel.tagged_with ["forking", "kiting"]  

	# Match all tags across any contexts
	TaggableModel.tagged_with ["forking", "kiting"], :all => true

	# Match any tag on a specific context
	TaggableModel.tagged_with ["math", "kiting"], :on => "skills"

	# Match all tags on a specific context
	TaggableModel.tagged_with ["math", "kiting"], :all => true, :on => "skills"

	# Mix with active relation 
	TaggableModel.tagged_with(["forking", "kiting"]).where( ["created_at > ?", Time.zone.now.ago(5.hours)])  


== Contributing to rocket_tag
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2011 Brad Phelan. See LICENSE.txt for
further details.

