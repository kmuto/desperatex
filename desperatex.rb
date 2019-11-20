# Copyright 2015-2019 Kenshi Muto <kmuto@debian.org>
# (damn) LaTeX Math to HTML parser
require 'rexml/document'
require 'rexml/streamlistener'

class DesperaTEX
  # escaped string: ゐ<cmd>:<value>ゑ
  EO = 'ゐ'.freeze
  EC = 'ゑ'.freeze

  def bs_map
    {
      '\{' => '<r>{</r>',
      '\}' => '<r>}</r>',
      '\｝' => '<r>}</r>',
      '\_' => '<r>_</r>',
      '\|' => '<r>|</r>',
      '\^' => '<r>^</r>',
      '\%' => '<r>%</r>',
      '\$' => '<r>$</r>',
      '\#' => '<r>#</r>',
      '\;' => "#{EO}SP#{EC}",
      '\<' => '◆→<←◆', # FIXME
      '\>' => ' ',
      '<' => '<r>＜</r>',
      '>' => '<r>＞</r>',
      '+' => '<r>＋</r>',
      '-' => '<r>−</r>',
      '*' => '<r>＊</r>',
      '/' => '<r>/</r>',
      '=' => '<r>＝</r>',
      '``' => "<r>\'</r>",
      "''" => '<r>"</r>',
      ', ' => ",#{EO}SP#{EC}" # FIXME
    }
  end

  def cmd_map
    {
      '\log' => '<r>log</r>',
      '\exp' => '<r>exp</r>',
      '\sin' => '<r>sin</r>',
      '\cos' => '<r>cos</r>',
      '\tan' => '<r>tan</r>',
      '\times' => '<r>×</r>',
      '\dots' => '<r>...</r>',
      '\cdots' => '<r>…</r>',
      '\cdot' => '<r>・</r>',
      '\equiv' => '<r>≡</r>',
      # '\leq' => '<r>≤</r>',
      # '\geq' => '<r>≥</r>',
      '\leq' => '<r>≦</r>',
      '\geq' => '<r>≧</r>',
      '\quad' => '<r>　</r>',
      '\pi' => 'π',
      '\sigma' => 'σ',
      '\theta' => 'θ',
      '\alpha' => 'α',
      '\beta' => 'Β',
      '\gamma' => 'γ',
      '\varGamma' => 'Γ',
      '\delta' => 'Δ',
      '\Delta' => 'Δ',
      '\epsilon' => 'ε',
      '\varepsilon' => 'ε',
      '\kappa' => 'κ',
      '\lambda' => 'λ',
      '\mu' => 'μ',
      '\rho' => 'ρ',
      '\tau' => 'τ',
      '\partial' => '∂',
      '\phi' => 'φ',
      '\Phi' => 'φ',
      '\varPhi' => 'φ',
      '\approx' => '<r>≈</r>',
      '\simeq' => '<r>≃</r>',
      '\fallingdotseq' => '<r>≒</r>',
      '\varpropto' => '<r>∝</r>',
      '\infty' => '<r>∞</r>',
      '\ ' => "#{EO}SP#{EC}"
    }
  end

  def initialize(mapfile = nil)
    @bs_escapes = bs_map
    @cmd_escapes = cmd_map

    @mbox_memory = []
    @mathit_memory = []
    @mathrm_memory = []
    @mathbm_memory = []
    @box_counter = 1

    @alternative_map = {}
    return if mapfile.nil? || !File.exist?(mapfile)
    File.open(mapfile) do |f|
      f.each_line do |l|
        next if l =~ /\A\#@\#/
        a = l.chomp.split("\t", 2)
        @alternative_map[a[0]] = a[1]
      end
    end
  end

  def tohtml(s)
    doc = REXML::Document.new(s)
    doc.each_element('//img') do |e|
      fname = e[0].to_s.gsub(/[A-Z]+/, 'L\&')
      fname = "sup.#{fname}" if from(e, 'sup')
      fname = "sub.#{fname}" if from(e, 'sub')
      fname = "b.#{fname}" if from(e, 'b')
      e[0].remove
      e.attributes['src'] = "images/math_symbols/#{fname}.png"
    end
    s = doc.to_s

    s.gsub('<r>', '<span class="math-normal">')
     .gsub('</r>', '</span>')
     .gsub('<rvbar>', '<span class="math-normal">')
     .gsub('</rvbar>', '</span>')
     .gsub('<ibar>', '<span class="math-italic-topbar">')
     .gsub('</ibar>', '</span>')
  end

  def toindesign(s)
    parse_xmlindesign(s)
  end

  def parse(orgs)
    if @alternative_map[orgs.gsub("\n", '◆')]
      # alternative override
      return @alternative_map[orgs.gsub("\n", '◆')]
    end

    s = orgs + ''

    begin
      s = escape_chars(s)
      s = numbering_bracket(s)
      s = supsub(s)
      s = bar(s)
      s = save_box(s)
      # FIXME: more parse
      s = space(s)
      s = unescape_chars(s)
      s = restore_box(s)
      s = unescape_chars(s) # inside mbox
    rescue StandardError => e
      raise DesperaTEXFailedException.new(orgs.gsub("\n", '◆')), "Unknown error: #{e}, #{orgs}"
    end

    if s =~ /[#{EO}#{EC}]/ || s =~ /\\/
      raise DesperaTEXFailedException.new(orgs.gsub("\n", '◆')), "Failed to handle this expression: #{orgs}"
    end

    "<i>#{s}</i>"
  end

  def space(s)
    s.gsub(',', ",#{EO}SP#{EC}") # space after ','
  end

  def bar(s)
    # \bar
    s.gsub(/\\bar#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/, '<ibar>\2</ibar>')
  end

  def supsub(s)
    # ^, _
    s = s.gsub(/\^#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/, '<sup>\2</sup>')
         .gsub(/\^([a-zA-Z0-9])/, '<sup>\1</sup>')
         .gsub(/\_#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/, '<sub>\2</sub>')
         .gsub(/\_([a-zA-Z0-9])/, '<sub>\1</sub>')
#    s = supsub(s) if s =~ /[_^]/
    s
  end

  def escape_chars(s)
    # Escape some characters
    @bs_escapes.keys.each_with_index do |c, i|
      s.gsub!(c, "#{EO}BSESC:#{i}#{EC}")
    end

    @cmd_escapes.keys.each_with_index do |c, i|
      s = s.gsub(Regexp.new("#{Regexp.escape(c)}([^a-zA-Z])"), "#{EO}CMESC:#{i}#{EC}" + '\1')
           .gsub(Regexp.new("#{Regexp.escape(c)}\\Z"), "#{EO}CMESC:#{i}#{EC}" + '\1')
    end
    s
  end

  def unescape_chars(s)
    # Unescape characters
    @cmd_escapes.keys.each_with_index do |c, i|
      s.gsub!("#{EO}CMESC:#{i}#{EC}", @cmd_escapes[c])
    end
    @bs_escapes.keys.each_with_index do |c, i|
      s.gsub!("#{EO}BSESC:#{i}#{EC}", @bs_escapes[c])
    end

    s
  end

  def numbering_bracket(s)
    # Numbering { }
    result = ''
    stack = []
    i = 0

    s.each_char do |c|
      if c == '{'
        stack.push(i)
        result << "#{EO}BO:#{i}#{EC}"
        i += 1
      elsif c == '}'
        result << "#{EO}BC:#{stack.pop}#{EC}"
      else
        result << c
      end
    end

    result
  end

  def save_box(s)
    s.gsub!(/\\mbox#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/) do
      s2 = restore_box($2.gsub(' ', "#{EO}SP#{EC}"))
      @mbox_memory[@box_counter] = "<r>#{s2}</r>"
      ret = "#{EO}MBOX" + ('a' * @box_counter) + EC
      @box_counter += 1
      ret
    end

    s.gsub!(/\\(?:rm|text|textrm|mathrm)#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/) do
      s2 = restore_box($2.gsub(' ', "#{EO}SP#{EC}"))
      @mathrm_memory[@box_counter] = "<r>#{s2}</r>"
      ret = "#{EO}MATHRM" + ('a' * @box_counter) + EC
      @box_counter += 1
      ret
    end

    s.gsub!(/\\mathit#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/) do
      s2 = restore_box($2.gsub(' ', "#{EO}SP#{EC}"))
      @mathit_memory[@box_counter] = "<i>#{s2}</i>"
      ret = "#{EO}MATHIT" + ('a' * @box_counter) + EC
      @box_counter += 1
      ret
    end

    s.gsub!(/\\(?:bm|mathbm|mathbf)#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/) do
      s2 = restore_box($2.gsub(' ', "#{EO}SP#{EC}"))
      @mathbm_memory[@box_counter] = "<b>#{s2}</b>"
      ret = "#{EO}MATHBM" + ('a' * @box_counter) + EC
      @box_counter += 1
      ret
    end
    s
  end

  def restore_box(s)
    s.gsub!(/[:;0-9()\[\]\{\}!,.]+/, '<r>\&</r>')

    s.gsub!(/#{EO}MBOX(a+)#{EC}/) { @mbox_memory[$1.size] }
    s.gsub!(/#{EO}MATHRM(a+)#{EC}/) { @mathrm_memory[$1.size] }
    s.gsub!(/#{EO}MATHIT(a+)#{EC}/) { @mathit_memory[$1.size] }
    s.gsub!(/#{EO}MATHBM(a+)#{EC}/) { @mathbm_memory[$1.size] }

    s.gsub('</r><r>', '').gsub('</i><i>', '')
     .gsub(' ', '').gsub("#{EO}SP#{EC}", ' ')
     .gsub("#{EO}LT#{EC}", '&lt;')
     .gsub("#{EO}GT#{EC}", '&gt;')
  end

  def from(e, name)
    while e != e.root
      return e if e.parent.name == name
      e = e.parent
    end
    nil
  end

  def parse_xmlindesign(s)
    doc = REXML::Document.new(s)
    doc.each_element('//sup//sup//sup|//sup//sup//sub|//sup//sub//sup|//sup//sub//sub|//sub//sup//sup|//sub//sup//sub|//sub//sub//sup|//sub//sub//sub') do
      raise DesperaTEXFailedException, 'too deep sup/sub'
    end

    doc.each_element('//sup') do |e|
      e.name = 'sup2' if from(e, 'sup')
      e.name = 'subsup' if from(e, 'sub')
      e.name = "b#{e.name}" if from(e, 'b')
    end
    doc.each_element('//sub') do |e|
      e.name = 'sub2' if from(e, 'sub')
      e.name = 'supsub' if from(e, 'sup')
      e.name = "b#{e.name}" if from(e, 'b')
    end

    doc.each_element('//b') do |e|
      e.name = 'rb' if from(e, 'r')
      %w[sup sub sup2 subsup sub2 supsub].each do |name|
        e.name = "b#{name}" if from(e, name)
      end
      %w[rsup rsub rsup2 rsubsup rsub2 rsupsub].each do |name|
        e.name = name.sub(/\Ar/, 'b') if from(e, name)
      end
      %w[bsup bsub bsup2 bsubsup bsub2 bsupsub].each do |name|
        e.name = name if from(e, name)
      end
    end

    doc.each_element('//i') do |e|
      e.name = 'b' if from(e, 'b')
      %w[sup sub sup2 subsup sub2 supsub bsup bsub bsup2 bsubsup bsub2 bsubsup].each do |name|
        e.name = name if from(e, name)
      end
    end

    doc.each_element('//r') do |e|
      e.name = 'rb' if from(e, 'b')
      %w[sup sub sup2 subsup sub2 supsub bsup bsub bsup2 bsubsup bsub2 bsubsup].each do |name|
        e.name = "r#{name}" if from(e, name)
      end
    end

    doc.each_element('//img') do |e|
      fname = e[0].to_s.gsub(/[A-Z]+/, 'L\&')
      fname = "sup.#{fname}" if from(e, 'sup')
      fname = "sub.#{fname}" if from(e, 'sub')
      fname = "b.#{fname}" if from(e, 'b')
      e[0].remove
      e.add_text(REXML::Text.new("◆→math:#{fname}.eps←◆"))
    end

    doc
  end
end

class DesperaTEXFailedException < RuntimeError
end
