module Sass
  module Tree
    class Node
      attr_accessor :children
      attr_accessor :line

      def initialize(style)
        @style = style
        @children = []
      end

      def <<(child)
        @children << validate_child(child)
      end
      
      def to_s
        result = String.new
        children.each do |child|
          if child.is_a? AttrNode
            raise SyntaxError.new('Attributes aren\'t allowed at the root of a document.', child.line)
          end

          result += "#{child.to_s(0)}\n"
        end
        result[0...-1]
      end

      private

      # This should be overridden to throw an error
      # in nodes where certain children are invalid.
      def validate_child(child)
        child
      end
    end
  end
end
