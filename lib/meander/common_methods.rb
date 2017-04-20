module Meander
  module CommonMethods # :nodoc:
    module ClassMethods # :nodoc:
      def hash_or_cover_class?(value)
        value.is_a?(Hash) || value.is_a?(cover_class)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.instance_eval do
        def cover_class=(val)
          @cover_class = val
        end

        def cover_class
          @cover_class ||= self
        end
      end
    end

    private

    def define_getter(method)
      define_singleton_method method do |&b|
        if key?(method)
          b.call(self[method]) if block_given?
          self[method]
        else
          instance_eval(method) do |name|
            undef_method name
          end
          send method, &block
        end
      end
    end

    def new_key_method?(method)
      method =~ /^([[:word:]]+)\=$/
    end
  end
end
