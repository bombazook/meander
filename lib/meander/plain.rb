# frozen_string_literal: true

require 'set'

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
  class Plain
    include CommonMethods
    include Enumerable

    def initialize(val = {})
      raise ArgumentError if val && !self.class.hash_or_cover_class?(val)

      @keys = Set.new
      eval_keys(val) if val
    end

    def keys
      @keys.to_a
    end

    def key?(key)
      @keys.member? convert_key(key)
    end

    def [](key)
      key = convert_key(key)
      if key? key
        __send__(convert_key(key))
      else
        nil
      end
    end

    def []=(key, value)
      key = convert_key(key)
      if key? key
        __send__("#{key}=", value)
      else
        eval_key(key, value)
      end
    end

    def each(&block)
      e = Enumerator.new do |yielder|
        @keys.each do |k|
          yielder.yield([k, __send__(k)])
        end
      end
      return e unless block_given?

      e.each(&block)
    end

    def delete(key)
      key = convert_key(key)
      @keys.delete key
      undef_accessors key if key.is_a? String
    end

    def merge!(other)
      other.each do |k, v|
        self[k] = v
      end
    end

    def method_missing(mname, *args, &block)
      method_name = convert_key(mname)
      if new_key_method? method_name
        key_name = method_name.gsub(/=$/, '')
        send :[]=, key_name, args[0]
      elsif block_given?
        eval_key(method_name, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      new_key_method?(convert_key(method_name)) || super
    end

    private

    def eval_keys(val)
      val.each do |key, value|
        eval_key(key, value)
      end
    end

    def eval_value_object(key)
      @keys.add key
      value_object = self.class.cover_class.new
      instance_variable_set "@#{key}", value_object
      yield value_object
      value_object
    end

    def eval_key(key, value = nil, &block)
      key = convert_key(key)
      @keys.add key
      instance_variable_set "@#{key}", value
      define_setter(key)
      define_getter(key)
      __send__("#{key}=", value)
      __send__(key, &block)
    rescue NameError => e
      delete key
      raise e
    end

    def define_setter(key)
      define_singleton_method "#{key}=" do |val|
        val = self.class.cover_class.new(val) if val.is_a? Hash
        instance_variable_set "@#{key}", val
      end
    end

    def define_getter(key)
      define_singleton_method key do |&block|
        val = instance_variable_get "@#{key}"
        if block
          if val.is_a?(self.class.cover_class)
            block.call(val)
          else
            val = eval_value_object(key, &block)
          end
        end
        val
      end
    end

    def undef_accessors(key)
      singleton_class.send :undef_method, key
      singleton_class.send :undef_method, "#{key}="
      remove_instance_variable(key)
    end
  end
end
