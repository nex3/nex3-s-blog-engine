module Haml
  # This class is used only internally. It holds the buffer of XHTML that
  # is eventually output by Haml::Engine's to_html method. It's called
  # from within the precompiled code, and helps reduce the amount of
  # processing done within instance_eval'd code.
  class Buffer
    include Haml::Helpers

    # Set the maximum length for a line to be considered a one-liner.
    # Lines <= the maximum will be rendered on one line,
    # i.e. <tt><p>Hello world</p></tt>
    ONE_LINER_LENGTH     = 50

    # The string that holds the compiled XHTML. This is aliased as
    # _erbout for compatibility with ERB-specific code.
    attr_accessor :buffer

    # Gets the current tabulation of the document.
    def tabulation
      @real_tabs + @tabulation
    end

    # Sets the current tabulation of the document.
    def tabulation=(val)
      val = val - @real_tabs
      @tabulation = val > -1 ? val : 0
    end

    # Creates a new buffer.
    def initialize(options = {})
      @options = {
        :attr_wrapper => "'"
      }.merge options
      @quote_escape = options[:attr_wrapper] == '"' ? "&quot;" : "&apos;"
      @other_quote_char = options[:attr_wrapper] == '"' ? "'" : '"'
      @buffer = ""
      @tabulation = 0

      # The number of tabs that Engine thinks we should have
      # @real_tabs + @tabulation is the number of tabs actually output
      @real_tabs = 0
    end

    # Renders +text+ with the proper tabulation. This also deals with
    # making a possible one-line tag one line or not.
    def push_text(text, tab_change = 0)
      if(@tabulation > 0)
        # Have to push every line in by the extra user set tabulation
        text.gsub!(/^/m, '  ' * @tabulation)
      end
      
      @buffer << "#{text}"
      @real_tabs += tab_change
    end

    # Properly formats the output of a script that was run in the
    # instance_eval.
    def push_script(result, flattened, close_tag = nil)
      tabulation = @real_tabs
      
      if flattened
        result = Haml::Helpers.find_and_preserve(result)
      end
      
      result = result.to_s
      while result[-1] == ?\n
        # String#chomp is slow
        result = result[0...-1]
      end
      
      if close_tag && Buffer.one_liner?(result)
        @buffer << result
        @buffer << "</#{close_tag}>\n"
        @real_tabs -= 1
      else
        if close_tag
          @buffer << "\n"
        end
        
        result = result.gsub(/^/m, tabs(tabulation))
        @buffer << "#{result}\n"
        
        if close_tag
          @buffer << "#{tabs(tabulation-1)}</#{close_tag}>\n"
          @real_tabs -= 1
        end
      end
      nil
    end

    # Takes the various information about the opening tag for an
    # element, formats it, and adds it to the buffer.
    def open_tag(name, atomic, try_one_line, class_id, obj_ref, content, attributes_hash)
      tabulation = @real_tabs
      
      attributes = class_id
      if attributes_hash
        attributes_hash.keys.each { |key| attributes_hash[key.to_s] = attributes_hash.delete(key) }
        self.class.merge_attrs(attributes, attributes_hash)
      end
      self.class.merge_attrs(attributes, parse_object_ref(obj_ref)) if obj_ref

      if atomic
        str = " />\n"
      elsif try_one_line
        str = ">"
      else
        str = ">\n"
      end
      @buffer << "#{tabs(tabulation)}<#{name}#{build_attributes(attributes)}#{str}"
      if content
        if Buffer.one_liner?(content)
          @buffer << "#{content}</#{name}>\n"
        else
          @buffer << "\n#{tabs(@real_tabs+1)}#{content}\n#{tabs(@real_tabs)}</#{name}>\n"
        end
      else
        @real_tabs += 1
      end
    end

    def self.merge_attrs(to, from)
      if to['id'] && from['id']
        to['id'] << '_' << from.delete('id')
      end

      if to['class'] && from['class']
        # Make sure we don't duplicate class names
        from['class'] = (from['class'].split(' ') | to['class'].split(' ')).join(' ')
      end

      to.merge!(from)
    end

    # Some of these methods are exposed as public class methods
    # so they can be re-used in helpers.

    # Takes a hash and builds a list of XHTML attributes from it, returning
    # the result.
    def build_attributes(attributes = {})
      result = attributes.collect do |a,v|
        unless v.nil?
          v = v.to_s
          attr_wrapper = @options[:attr_wrapper]
          if v.include? attr_wrapper
            if v.include? @other_quote_char
              v = v.gsub(attr_wrapper, @quote_escape)
            else
              attr_wrapper = @other_quote_char
            end
          end
          " #{a}=#{attr_wrapper}#{v}#{attr_wrapper}"
        end
      end
      result.sort.join
    end
    
    # Returns whether or not the given value is short enough to be rendered
    # on one line.
    def self.one_liner?(value)
      value.length <= ONE_LINER_LENGTH && value.scan(/\n/).empty?
    end

    private

    @@tab_cache = {}
    # Gets <tt>count</tt> tabs. Mostly for internal use.
    def tabs(count)
      tabs = count + @tabulation
      '  ' * tabs
      @@tab_cache[tabs] ||= '  ' * tabs
    end

    # Takes an array of objects and uses the class and id of the first
    # one to create an attributes hash.
    def parse_object_ref(ref)
      ref = ref[0]
      # Let's make sure the value isn't nil. If it is, return the default Hash.
      return {} if ref.nil?
      class_name = underscore(ref.class)
      id = "#{class_name}_#{ref.id || 'new'}"

      {'id' => id, 'class' => class_name}
    end

    # Changes a word from camel case to underscores.
    # Based on the method of the same name in Rails' Inflector,
    # but copied here so it'll run properly without Rails.
    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '_').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end

unless String.methods.include? 'old_comp'
  class String # :nodoc
    alias_method :old_comp, :<=>
    
    def <=>(other)
      if other.is_a? NilClass
        -1
      else
        old_comp(other)
      end
    end
  end
    
  class NilClass # :nodoc:
    include Comparable
    
    def <=>(other)
      other.nil? ? 0 : 1
    end
  end
end

