# typed: ignore
# frozen_string_literal: true

require "test_helper"
require "parser_test_helper"

module Packwerk
  class AssociationInspectorTest < Minitest::Test
    setup do
      @inflector = Inflector.new(custom_inflector: Inflections::Custom.new)
    end

    test "#association? understands custom associations" do
      node = parse("has_lots :order")
      inspector = AssociationInspector.new(inflector: @inflector, custom_associations: [:has_lots])

      assert_equal "Order", inspector.constant_name_from_node(node, ancestors: [])
    end

    test "finds target constant for simple association" do
      node = parse("has_one :order")
      inspector = AssociationInspector.new(inflector: @inflector)

      assert_equal "Order", inspector.constant_name_from_node(node, ancestors: [])
    end

    test "finds target constant for association that pluralizes" do
      node = parse("has_many :orders")
      inspector = AssociationInspector.new(inflector: @inflector)

      assert_equal "Order", inspector.constant_name_from_node(node, ancestors: [])
    end

    test "finds target constant for association if explicitly specified" do
      node = parse("has_one :cool_order, { class_name: 'Order' }")
      inspector = AssociationInspector.new(inflector: @inflector)

      assert_equal "Order", inspector.constant_name_from_node(node, ancestors: [])
    end

    test "rejects method calls that are not associations" do
      node = parse('puts "Hello World"')
      inspector = AssociationInspector.new(inflector: @inflector)

      assert_nil inspector.constant_name_from_node(node, ancestors: [])
    end

    test "passes on association usage in migrations" do
      migration = parse(
        <<~RUBY
          class MyFancyMigration < ActiveRecord::Migration[6.0]
            create_table(:my_table) do |t|
              t.belongs_to :order
            end
          end
        RUBY
      )
      ancestors = [migration.children[2], migration]
      node = migration.children[2].children.last
      inspector = AssociationInspector.new(inflector: @inflector)

      assert_nil inspector.constant_name_from_node(node, ancestors: ancestors)
    end

    test "gives up on metaprogrammed associations" do
      node = parse("has_one association_name")
      inspector = AssociationInspector.new(inflector: @inflector)

      assert_nil inspector.constant_name_from_node(node, ancestors: [])
    end

    test "gives up on dynamic class name" do
      node = parse("has_one :order, class_name: Order.name")
      inspector = AssociationInspector.new(inflector: @inflector)

      assert_nil inspector.constant_name_from_node(node, ancestors: [])
    end

    private

    def parse(statement)
      ParserTestHelper.parse(statement)
    end
  end
end
