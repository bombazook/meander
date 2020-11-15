# frozen_string_literal: true

require 'thor/core_ext/hash_with_indifferent_access'
require_relative 'common_methods'
module Meander
  ##
  # == Brief
  # This class is a sugar filled version of HashWithIndifferentAccess
  #
  # It supports key-based method_name calling and value block evaluation
  # == Configuration
  # You can set class that will be applied to newly assigned values
  #   require 'active_support/core_ext/hash'
  #   class MyClass < Meander::Plain
  #     cover_class = HashWithIndifferentAccess
  #   end
  #
  #   m = MyClass.new
  #   m[:a] = {}
  #   m[:a].class # => ActiveSupport::HashWithIndifferentAccess
  # == Usage
  # === Key based method_name evaluation
  #   m = Meander::Plain.new({:a => 1})
  #   m.a # => 1
  # === New value assignment
  #   n = Meander::Plain.new
  #   n.a = 1
  #   n.a # => 1
  # === Block values evaluation
  #   k = Meander::Plain.new({config: nil})
  #   k.config do |k|
  #     k.path = "some_config_path.yml"
  #   end
  #   k.config.path # => "some_config_path.yml"
  class Plain < ::Thor::CoreExt::HashWithIndifferentAccess
    include CommonMethods

    def initialize(val = {})
      val ||= {}
      super(val)
    end

    def []=(key, value)
      if value.is_a?(Hash) && !value.is_a?(self.class.cover_class)
        super(key, self.class.cover_class.new(value))
      else
        super
      end
    end

    def method_missing(method_name, *args, &block)
      method_name = method_name.to_s
      if new_key_method? method_name
        key_name = method_name.gsub(/=$/, '')
        send :[]=, key_name, *args, &block
      elsif block_given?
        val = self[method_name]
        val = {} unless self.class.hash_or_cover_class?(val)
        send :[]=, method_name, val
        yield(self[method_name])
      elsif key?(method_name)
        self[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      new_key_method?(method_name) || key?(method_name) || super
    end
  end
end
