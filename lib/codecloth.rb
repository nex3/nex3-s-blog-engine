require 'rubygems'
require 'redcloth'
require 'coderay'

module CodeCloth
  HTML_OPTIONS = { :wrap => :div }

  def self.included(other)
    other::BASIC_TAGS['span'] = ['class']
    other::BASIC_TAGS['div'] = ['class']
    other::BASIC_TAGS['codeclothpre'] = nil

    other::DEFAULT_RULES.insert 0, :block_syntax_set

    other.send :alias_method, :to_html_without_syntax, :to_html
    other.send :alias_method, :to_html, :to_html_with_syntax

    other.send :alias_method, :initialize_without_scanner, :initialize
    other.send :alias_method, :initialize, :initialize_with_scanner
  end

  def initialize_with_scanner(*whatever)
    initialize_without_scanner(*whatever)
    @scanner = CodeRay::Scanners['plain']
  end

  def block_syntax_set(text)
    return nil if text[0] != ?$
    syntax, rest = text.split "\n", 2

    syntax.slice! 0
    syntax.strip!
    syntax.downcase!

    scanner = CodeRay::Scanners[syntax.empty? ? 'plain' : syntax]

    if rest.nil?
      @scanner = scanner
      text.replace('')
    else
      text.replace rest.gsub(/^#{'\s' * rest.index(/[^\s]/)}/, '')
      blocks text, true
      syntaxify text, scanner
      text
    end
  end

  def to_html_with_syntax(*whatever)
    unescape_pre syntaxify(syntaxify_manual_html(to_html_without_syntax(*whatever)), @scanner)
  end

  private

  SYNTAXLESS_CODE_RE = /<pre>(?:<code>)?(.*?)(?:<\/code>)?<\/pre>/m

  def syntaxify(text, scanner)
    text.gsub!(SYNTAXLESS_CODE_RE) do
      escape_pre scanner.new($1).tokenize.html(HTML_OPTIONS)
    end
    text
  end

  MANUAL_HTML_RE = /^\$([^\n]+)\n(#{SYNTAXLESS_CODE_RE})/

  def syntaxify_manual_html(text)
    text.gsub!(MANUAL_HTML_RE) do
      syntaxify $2, CodeRay::Scanners[$1.strip.downcase]
    end
    text
  end

  def escape_pre(text)
    text.gsub(/<(\/?)pre>/, '<\1codeclothpre>')
  end

  def unescape_pre(text)
    text.gsub(/<(codeclothpre)>(.*?)<\/\1>/m) do
      "<pre>#{$2.gsub('&amp;', '&')}</pre>"
    end
  end
end

RedCloth.send :include, CodeCloth
