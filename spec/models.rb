class TaggableModel < ActiveRecord::Base
  default_scope do
    preload{taggings}.preload{tags}
  end

  attr_taggable
  attr_taggable :languages
  attr_taggable :skills
  attr_taggable :needs, :offerings
  has_many :untaggable_models
  belongs_to :user
end

class User < ActiveRecord::Base
  has_many :taggable_models
end

class CachedModel < ActiveRecord::Base
  attr_taggable
end

class OtherCachedModel < ActiveRecord::Base
  attr_taggable :languages, :statuses, :glasses
end

class OtherTaggableModel < ActiveRecord::Base
  attr_taggable :tags, :languages
  attr_taggable :needs, :offerings
end

class InheritingTaggableModel < TaggableModel
end

class AlteredInheritingTaggableModel < TaggableModel
  attr_taggable :parts
end

class UntaggableModel < ActiveRecord::Base
  belongs_to :taggable_model
end

class NonStandardIdTaggableModel < ActiveRecord::Base
  primary_key = "an_id"
  attr_taggable
  attr_taggable :languages
  attr_taggable :skills
  attr_taggable :needs, :offerings
  has_many :untaggable_models
end

