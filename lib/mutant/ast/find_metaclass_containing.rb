# frozen_string_literal: true

module Mutant
  class AST
    # Given an AST, finds the sclass that directly(-ish) contains the provided
    # node.
    # This won't match arbitrarily complex structures - it only searches the
    # first level deep (no begins-in-begins, for example). This is in
    # keeping with mutant generally not supporting 'weird' syntax.
    # Descending into 'begin' nodes is supported because these are generated for
    # the one-line syntax class << self; def foo; end
    class FindMetaclassContaining
      include NodePredicates, Concord.new(:ast, :target), Procto

      SCLASS_BODY_INDEX = 1

      private_constant(*constants(false))

      # Find metaclass node containing target node
      #
      # @return [Parser::AST::Node, nil]
      #
      # @api private
      def call
        Structure.for(ast.node.type).each_node(ast.node) do |current|
          return current if n_sclass?(current) && metaclass_of?(current)
        end

        nil
      end

    private

      def metaclass_of?(sclass)
        body = sclass.children.fetch(SCLASS_BODY_INDEX)
        body.equal?(target) || transparently_contains?(body)
      end

      def transparently_contains?(body)
        n_begin?(body) && include_exact?(body.children, target)
      end

      def include_exact?(haystack, needle)
        haystack.any? { |elem| elem.equal?(needle) }
      end
    end
  end
end
