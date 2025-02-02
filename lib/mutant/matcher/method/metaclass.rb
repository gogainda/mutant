# frozen_string_literal: true

module Mutant
  class Matcher
    class Method
      # Matcher for metaclass methods
      # i.e. ones defined using class << self or class << CONSTANT. It might??
      # work for methods defined like class << obj, but I don't think the
      # plumbing will be in place in the subject for that to work
      class Metaclass < self

        # New singleton method matcher
        #
        # @param [Class, Module] scope
        # @param [Symbol] method_name
        #
        # @return [Matcher::Method::Singleton]
        def self.new(scope, method_name)
          super(scope, method_name, Evaluator)
        end

        # Metaclass method evaluator
        class Evaluator < Evaluator
          # Terminology note: the "receiver" is the `self` in `class << self`
          CONST_NAME_INDEX      = 1
          MATCH_NODE_TYPE       = :def
          NAME_INDEX            = 0
          SCLASS_RECEIVER_INDEX = 0
          SUBJECT_CLASS         = Subject::Method::Metaclass
          RECEIVER_WARNING      = 'Can only match :def inside :sclass on ' \
                                  ':self or :const, got :sclass on %p ' \
                                  'unable to match'

        private

          def match?(node)
            n_def?(node) &&
              name?(node) &&
              line?(node) &&
              metaclass_receiver?(node)
          end

          def metaclass_receiver?(node)
            candidate = metaclass_containing(node)
            candidate && metaclass_target?(candidate)
          end

          def metaclass_containing(node)
            AST::FindMetaclassContaining.call(ast, node)
          end

          def line?(node)
            node
              .location
              .line
              .equal?(source_line)
          end

          def name?(node)
            node.children.fetch(NAME_INDEX).equal?(method_name)
          end

          def metaclass_target?(node)
            receiver = node.children.fetch(SCLASS_RECEIVER_INDEX)
            case receiver.type
            when :self
              true
            when :const
              sclass_const_name?(receiver)
            else
              env.warn(RECEIVER_WARNING % receiver.type)
              nil
            end
          end

          def sclass_const_name?(node)
            name = node.children.fetch(CONST_NAME_INDEX)
            name.to_s.eql?(context.unqualified_name)
          end

        end # Evaluator

        private_constant(*constants(false))
      end # Metaclass
    end # Method
  end # Matcher
end # Mutant
