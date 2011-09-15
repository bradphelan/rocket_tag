require "active_record"
require "rocket_tag/tagging"
require "rocket_tag/tag"

require "rocket_tag/taggable"

if defined?(ActiveRecord::Base)
  class ActiveRecord::Base
    include RocketTag::Taggable
  end
end
