require 'set'

module Grape
  class Entity
    class Exposure
      attr_reader :options

      # All supported options.
      OPTIONS = [
        :as, :if, :unless, :using, :with, :proc, :documentation, :format_with, :safe, :if_extras, :unless_extras
      ].to_set.freeze

      def initialize(options)
        @options = options
      end

      # Raises an error if the given options include unknown keys.
      # Renames aliased options.
      #
      # @param options [Hash] Exposure options.
      def self.valid_options(options)
        options.keys.each do |key|
          fail ArgumentError, "#{key.inspect} is not a valid option." unless OPTIONS.include?(key)
        end

        options[:using] = options.delete(:with) if options.key?(:with)
        options
      end

      # Merges the given options with current block options.
      #
      # @param options [Hash] Exposure options.
      def self.merge_options(options)
        opts = {}

        merge_logic = proc do |key, existing_val, new_val|
          if [:if, :unless].include?(key)
            if existing_val.is_a?(Hash) && new_val.is_a?(Hash)
              existing_val.merge(new_val)
            elsif new_val.is_a?(Hash)
              (opts["#{key}_extras".to_sym] ||= []) << existing_val
              new_val
            else
              (opts["#{key}_extras".to_sym] ||= []) << new_val
              existing_val
            end
          else
            new_val
          end
        end

        @block_options ||= []
        opts.merge @block_options.inject({}) { |final, step|
          final.merge(step, &merge_logic)
        }.merge(valid_options(options), &merge_logic)
      end

      OPTIONS.each do |opt|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{opt}
            @options[:#{opt}]
          end

          def #{opt}?
            @options.key? :#{opt}
          end
        RUBY
      end

      def [](key)
        options[key]
      end

      def key?(key)
        options.key? key
      end

      def []=(key, value)
        options[key] = value
      end

      def to_hash
        options
      end
    end
  end
end
