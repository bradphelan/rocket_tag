module RocketTag
  class Tagging < ::ActiveRecord::Base

    belongs_to :tag, :class_name => 'RocketTag::Tag'
    belongs_to :taggable, :polymorphic => true
    belongs_to :tagger,   :polymorphic => true

    validates_presence_of :context
    validates_presence_of :tag_id

    validates_uniqueness_of :tag_id, :scope => [ :taggable_type, :taggable_id, :context, :tagger_id, :tagger_type ]
  end
end
