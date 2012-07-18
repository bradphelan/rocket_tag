require "active_record"

$LOAD_PATH.unshift(File.dirname(__FILE__))

require "rocket_tag/tagging"
require "rocket_tag/tag"
require "rocket_tag/alias_tag"
require "rocket_tag/taggable"

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  class ActiveRecord::Base
    include RocketTag::Taggable
  end
end
