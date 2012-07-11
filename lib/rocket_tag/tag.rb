module RocketTag
  class Tag < ActiveRecord::Base
    has_many :taggings, :dependent => :destroy, :class_name => 'RocketTag::Tagging'
    attr_accessible :name

    validates_presence_of :name
    validates_uniqueness_of :name

    def self.by_taggable_type(type)
      joins{taggings}.where{taggings.taggable_type == type.to_s}
    end

    def tags_count
      self[:tags_count].to_i
    end

  end
end
