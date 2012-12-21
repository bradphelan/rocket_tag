module RocketTag
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def clean_tags(tags)
      return tags unless tags.is_a?(Array)

      tags = tags.dup
      tags = tags.map(&:downcase) if RocketTag.configuration.force_lowercase
      tags
    end
  end
end

require "active_record"

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rocket_tag/configuration'
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
