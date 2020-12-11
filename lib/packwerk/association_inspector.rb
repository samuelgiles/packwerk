# typed: true
# frozen_string_literal: true

require "packwerk/constant_name_inspector"
require "packwerk/node"

module Packwerk
  # Extracts the implicit constant reference from an active record association
  class AssociationInspector
    extend T::Sig
    include ConstantNameInspector

    RAILS_ASSOCIATIONS = %i(
      belongs_to
      has_many
      has_one
      has_and_belongs_to_many
    ).to_set

    def initialize(inflector:, custom_associations: Set.new)
      @inflector = inflector
      @associations = RAILS_ASSOCIATIONS + custom_associations
    end

    def constant_name_from_node(node, ancestors:)
      return unless Node.method_call?(node)
      return unless association?(node)

      arguments = Node.method_arguments(node)
      return unless (association_name = association_name(arguments))
      return if within_db_migration?(ancestors)

      if (class_name_node = custom_class_name(arguments))
        return unless Node.string?(class_name_node)
        Node.literal_value(class_name_node)
      else
        @inflector.classify(association_name.to_s)
      end
    end

    private

    def association?(node)
      method_name = Node.method_name(node)
      @associations.include?(method_name)
    end

    ACTIVE_RECORD_MIGRATION_CLASS_NAME = "ActiveRecord::Migration"

    sig { params(ancestors: T::Array[AST::Node]).returns(T::Boolean) }
    def within_db_migration?(ancestors)
      migration = ancestors.find { |node| Node.class?(node) }
      migration_parent_class = migration && Node.parent_class(migration)&.children&.first
      return false unless migration_parent_class

      Node.constant_name(migration_parent_class) == ACTIVE_RECORD_MIGRATION_CLASS_NAME
    end

    def custom_class_name(arguments)
      association_options = arguments.detect { |n| Node.hash?(n) }
      return unless association_options

      Node.value_from_hash(association_options, :class_name)
    end

    def association_name(arguments)
      return unless Node.symbol?(arguments[0])

      Node.literal_value(arguments[0])
    end
  end
end
