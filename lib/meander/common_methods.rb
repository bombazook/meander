# frozen_string_literal: true

module Meander
  module CommonMethods # :nodoc:
    module ClassMethods # :nodoc:
      def hash_or_cover_class?(value)
        value.is_a?(Hash) || value.is_a?(cover_class)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      class << base
        attr_writer :cover_class

        def cover_class
          @cover_class ||= self
        end
      end
    end

    private

    def new_key_method?(method_name)
      /=$/.match?(method_name)
    end
  end
end
