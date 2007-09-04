require 'rubygems'
require 'redcloth'
require 'coderay'

module CodeCloth
  def self.included(other)
    other::DEFAULT_RULES.insert 0, :block_syntax_set
    other.send :alias_method, :blocks_without_syntax, :blocks
    other.send :alias_method, :blocks, :blocks_with_syntax
  end

  def block_syntax_set(text)
    return nil if text[0] != ?$
    syntax, rest = text.split "\n", 2

    syntax.slice! 0
    syntax.strip!
    syntax.downcase!

    @scanner = CodeRay::Scanners[syntax.empty? ? 'plain' : syntax]

    unless rest
      text.replace('')
      return true
    end

    text.replace("\t<pre class='CodeRay #{@scanner.plugin_id}'><code>#{
      @scanner.new(rest.gsub(/^#{'\s' * rest.index(/[^\s]/)}/, '')).tokenize.html
    }</pre></code>")
  end

  SYNTAXLESS_CODE_RE = /<pre><code>(.*?)<\/code><\/pre>/m

  def blocks_with_syntax(*whatever)
    res = blocks_without_syntax(*whatever)
    return if res.nil? || @scanner.nil? || @scanner == CodeRay::Scanners['plain']

    res.gsub!(SYNTAXLESS_CODE_RE) do
      "\t<pre class='CodeRay #{@scanner.plugin_id}'><code>#{@scanner.new($1).tokenize.html}</code></pre>"
    end
  end
end

RedCloth.send :include, CodeCloth
