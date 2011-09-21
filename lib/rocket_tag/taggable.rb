require 'squeel'

module RocketTag
  module Taggable
    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    class Manager

      attr_reader :contexts
      attr_writer :contexts
      attr_reader :klass

      def self.parse_tags list
        require 'csv'
        if list.kind_of? String
          # for some reason CSV parser cannot handle
          #     
          #     hello, "foo"
          #
          # but must be
          #
          #     hello,"foo"

          list = list.gsub /,\s+"/, ',"'
          list = list.parse_csv.map &:strip
        else
          list
        end
      end

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

    def taggings_for_context context
      taggings.where{taggings.context==my{context}}
    end

    def destroy_tags_for_context context
      taggings_for_context(context).delete_all
    end

    module InstanceMethods
      def tagged_similar options = {}
        context = options.delete :on
        raise Exception.new("#{context} is not a valid tag context for #{self.class}") unless self.class.rocket_tag.contexts.include? context
        if context
          contexts = [context]
        else
          contexts = self.class.rocket_tag.contexts
        end
        tags = send context.to_sym
        self.class.tagged_with(tags, options).where{id != my{id}}
      end
    end

    module ClassMethods

      def rocket_tag
        @rocket_tag ||= RocketTag::Taggable::Manager.new(self)
      end

      def _with_tag_context context
        if context
          where{taggings.context == my{context} }
        else
          where{ }
        end
      end

      def _with_min min, tags_list
        min = 1 unless min and min > 0
        group{~id}.
        having{count(~id)>=my{min}}
      end

      # Generates a sifter or a where clause depending on options.
      # The sifter generates a subselect with the body of the
      # clause wrapped up so that it can be used as a condition
      # within another squeel statement. 
      #
      # Query optimization is left up to the SQL engine.
      def tagged_with_sifter tags_list, options = {}
        on = options.delete :on
        all = options.delete :all
        min = options.delete(:min)
        if all
          min = tags_list.length
        end

        lambda do |&block|
            if options.delete :where
              where &block
            else
              squeel &block
            end
        end.call do
          id.in(
            my{self}.
              select{id}.
              joins{tags}.
              where{tags.name.in(my{tags_list})}.
              _with_tag_context(on).
              _with_min(min, tags_list)
          )
        end

      end

      # Generates a query that provides the matches
      # along with an extra column :count_tags.
      #
      # Be careful using this as it uses SQL group by
      # having without shielding with a sub select
      # so when chained with any other aggregate functions
      #
      # such as ActiveRecord::Calculations::ClassMethods::count
      #
      # http://ar.rubyonrails.org/classes/ActiveRecord/Calculations/ClassMethods.html
      #
      # you may not get the result you expect. However being provided
      # the column count_tags allows you to do further filtering
      # based on this score
      def tagged_with_scored tags_list, options = {}
        on = options.delete :on
        all = options.delete :all
        min = options.delete(:min)
        if all
          min = tags_list.length
        end

        select{count(~id).as(count_tags)}
          .select("#{self.table_name}.*").
          joins{tags}.
          where{tags.name.in(my{tags_list})}.
          _with_tag_context(on).
          _with_min(min, tags_list).
          order("count_tags DESC")

      end

      def related_tags_for(context, klass, options = {})
        tags_to_find = tags_on(context).collect { |t| t.name }

        exclude_self = "#{klass.table_name}.#{klass.primary_key} != #{id} AND" if self.class == klass

        group_columns = ActsAsTaggableOn::Tag.using_postgresql? ? grouped_column_names_for(klass) : "#{klass.table_name}.#{klass.primary_key}"

        klass.scoped({ :select     => "#{klass.table_name}.*, COUNT(tags.id) AS count",
                       :from       => "#{klass.table_name}, tags, taggings",
                       :conditions => ["#{exclude_self} #{klass.table_name}.#{klass.primary_key} = taggings.taggable_id AND taggings.taggable_type = '#{klass.to_s}' AND taggings.tag_id = tags.id AND tags.name IN (?)", tags_to_find],
                       :group      => group_columns,
                       :order      => "count DESC" }.update(options))
      end

        

      def tagged_with tags_list, options = {}
        options[:where] = true
        tagged_with_sifter(tags_list, options)
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
              list = Manager.parse_tags list

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
