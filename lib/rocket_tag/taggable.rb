require 'squeel'

module RocketTag
  module Taggable
    def self.included(base)
      base.extend ClassMethods
    end

    class Manager

      attr_reader :contexts
      attr_writer :contexts
      attr_reader :klass

      def initialize klass
        @klass = klass
        @contexts = Set.new
        setup_relations
      end

      def setup_relations
        klass.has_many :taggings , :dependent => :destroy , :as => :taggable, :class_name => "RocketTag::Tagging"
        klass.has_many :tags     , :source => :tag, :through => :taggings, :class_name => "RocketTag::Tag"
      end


    end

    def tags_for_context context
      tags.where{taggings.context==my{context}}
    end

    def taggings_for_context context
      taggings.where{taggings.context==my{context}}
    end

    def destroy_tags_for_context context
      taggings_for_context(context).delete_all
    end

    module ClassMethods

      def rocket_tag
        @rocket_tag ||= RocketTag::Taggable::Manager.new(self)
      end

      def with_tag_context context
        if context
          where{taggings.context == my{context} }
        else
          where{}
        end
      end

      def tagged_with tags_list, options = {}

        on = options.delete :on
        all = options.delete :all

        q = if all
              joins{tags}.where{
                id.in( 
                    my{self}.
                      select{id}.
                      joins{tags}.
                      where{tags.name.in(my{tags_list})}.
                      group{~id}.
                      having{count(~id)==my{tags_list.length}}.
                      with_tag_context(my{on})
                )
              }
        else
          joins{tags}.where{tags.name.in(my{tags_list})}.with_tag_context(on)
        end

        q.select{"distinct #{my{table_name}}.*"}

      end

      def attr_taggable *contexts

        if contexts.blank?
          contexts = [:tag]
        end

        rocket_tag.contexts += contexts

        contexts.each do |context|
          class_eval do

            default_scope do
              preload{taggings}.preload{tags}
            end

            has_many "#{context}_taggings".to_sym, 
              :source => :taggable,  
              :as => :taggable,
              :conditions => { :context => context }

            has_many "#{context}_tags".to_sym,
              :source => :tag,
              :through => :taggings,
              :conditions => [ "taggings.context = ?", context ]


            validate context do
              if not send(context).kind_of? Enumerable
                errors.add context, :invalid
              end
            end
            before_save do
              @tag_dirty ||= Set.new

              @tag_dirty.each do |context|
                # Get the current tags for this context
                list = send(context)

                # Destroy all taggings
                destroy_tags_for_context context

                # Find existing tags
                exisiting_tags = Tag.where{name.in(my{list})}
                exisiting_tag_names = exisiting_tags.map &:name

                # Find missing tags
                tags_names_to_create = list - exisiting_tag_names 

                # Create missing tags
                created_tags = tags_names_to_create.map do |tag_name|
                  Tag.create :name => tag_name
                end

                # Recreate taggings
                tags_to_assign = exisiting_tags + created_tags

                tags_to_assign.each do |tag|
                  tagging = Tagging.new :tag => tag, :taggable => self, :context => context, :tagger => nil
                  self.taggings << tagging
                end
              end
              @tag_dirty = Set.new
            end

            def reload
              super
              self.class.rocket_tag.contexts.each do |context|
                write_attribute context, []
              end
              @tags_cached = false
              cache_tags
            end

            define_method "cache_tags" do
              unless @tags_cached
                tags_by_context ||= send("taggings").group_by{|f| f.context }
                tags_by_context.each do |context,v|
                  write_attribute context, v.map{|t| t.tag.name}
                end
                @tags_cached = true
              end
            end

            # Return an array of RocketTag::Tags for the context
            define_method "#{context}" do
              cache_tags
              r = read_attribute(context) || []
            end


            define_method "#{context}=" do |list|

              # Ensure the tags are loaded
              cache_tags
              write_attribute(context, list)

              (@tag_dirty ||= Set.new) << context

                
            end
          end
        end
      end

    end

  end
end
