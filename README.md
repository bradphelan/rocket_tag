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
	
Take advantage of the tags_count synthetic column returned with every query

    TaggableModel.tagged_with(["math", "kiting", "coding", "sleeping"], :on => "skills").where{tags_count>=2}	

Mix with active relation 

    TaggableModel.tagged_with(["forking", "kiting"]).where( ["created_at > ?", Time.zone.now.ago(5.hours)])  

Find similar models based on tags on a specific context and return in decending order
of 'tags_count'

    model.tagged_similar :on => "skills"
    model.tagged_similar :on => "habits"

Find similar models based on tags on every context and return in decending order
of 'tags_count'. Note that each tag is still scoped according to it's context

    model.tagged_similar  

For reference the SQL generated for model.find_similar when there are
context [:skills, :languages] available is

      SELECT "taggable_models".* FROM   
            (
              SELECT COUNT("taggable_models"."id") AS tags_count, 
                     taggable_models.* 
              FROM   "taggable_models" 
                     INNER JOIN "taggings" 
                       ON "taggings"."taggable_id" = "taggable_models"."id" 
                          AND "taggings"."taggable_type" = 'TaggableModel' 
                     INNER JOIN "tags" 
                       ON "tags"."id" = "taggings"."tag_id" 
              WHERE  "taggable_models"."id" != 2 
                     AND ((   ( "tags"."name" IN ( 'german', 'french' ) AND "taggings"."context" = 'languages' ) 
                           OR ( "tags"."name" IN ( 'a', 'b', 'x' )      AND "taggings"."context" = 'skills' ) 
                         )) 
              GROUP  BY "taggable_models"."id" 
              ORDER  BY tags_count DESC
            ) taggable_models 


Note the aliasing of the inner select to shield the GROUP BY from downstream active relation
queries

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

Available for hire for your next ROR project at <a href="http://xtargets.com" title="XTargets: Ruby On Rails Solutions" rel="author">XTargets: Ruby On Rails Solutions</a>

