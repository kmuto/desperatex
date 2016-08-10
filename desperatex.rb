# coding: utf-8
# Copyright 2015 Kenshi Muto <kmuto@debian.org>
# (damn) LaTeX Math to HTML parser

class DesperaTEX
  # escaped string: ゐ<cmd>:<value>ゑ
  EO = "ゐ"
  EC = "ゑ"

  def initialize(mapfile = nil)
    @bs_escapes = {
      '\{' => "{",
      '\}' => "}",
      '\｝' => "}",
      '\_' => "_",
      '\|' => "|",
      '\^' => "^",
      '\%' => "%",
      '\$' => "$",
      '\#' => "#",
      '\;' => "#{EO}SP#{EC}",
      '\<' => "◆→<←◆", # FIXME
      '\>' => "◆→>←◆", # FIXME
      '<' => "<r>＜</r>",
      '>' => "<r>＞</r>",
      '+' => "<r>＋</r>",
      '-' => "<r>−</r>",
      '*' => "<r>＊</r>",
      '/' => "<r>/</r>",
      '=' => "<r>＝</r>",
      "``" => "<r>\"</r>",
      "''" => "<r>\"</r>",
      ', ' => ",#{EO}SP#{EC}", # FIXME
      }

    @cmd_escapes = {
      '\log' => "<r>log</r>",
      '\times' => "<r>×</r>",
      '\cdots' => "<r>…</r>",
      '\cdot' => "<r>・</r>",
      '\leq' => "<r>≦</r>",
      '\geq' => "<r>≧</r>",
      '\quad' => "　",
      '\pi' => "π",
      '\sigma' => "σ",
      '\ ' => "#{EO}SP#{EC}",
    }

    @mbox_memory = []
    @mathit_memory = []
    @box_counter = 1

    @alternative_map = {}
    if mapfile && File.exist?(mapfile)
      File.open(mapfile) do |f|
        f.each_line do |l|
          next if l =~ /\A\#@\#/
          a = l.chomp.split("\t", 2)
          @alternative_map[a[0]] = a[1]
        end
      end
    end
  end

  def tohtml(s)
    s.gsub("<r>", "<span class='math-normal'>").
      gsub("</r>", "</span>").
      gsub("<rvbar>", "<span class='math-normal'>").
      gsub("</rvbar>", "</span>").
      gsub("<ibar>", "<span class='math-italic-topbar'>").
      gsub("</ibar>", "</span>")
  end

  def parse(_s)
    if @alternative_map[_s.gsub("\n", "◆")]
      # alternative override
      return @alternative_map[_s.gsub("\n", "◆")]
    end

    s = _s + ""

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
    rescue Exception=>e
      STDERR.puts "Unknown error: #{e}, #{_s}"
      raise DesperaTEXFailedException.new(_s.gsub("\n", "◆"))
    end

    if s =~ /[#{EO}#{EC}]/ || s =~ /\\/
      raise DesperaTEXFailedException.new(_s.gsub("\n", "◆"))
    end

    return "<i>#{s}</i>"
  end

  def space(s)
    s.gsub!(",", ",#{EO}SP#{EC}") # space after ","
    s
  end

  def bar(s)
    # \bar
    s.gsub(/\\bar#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/, '<ibar>\2</ibar>')
  end

  def supsub(s)
    # ^, _
    s = s.gsub(/\^#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/, '<sup>\2</sup>').
      gsub(/\^([a-zA-Z0-9]+?)/, '<sup>\1</sup>').
      gsub(/\_#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/, '<sub>\2</sub>').
      gsub(/\_([a-zA-Z0-9]+?)/, '<sub>\1</sub>')

    if s =~ /[_^]/
      s = supsub(s)
    end

    s
  end

  def escape_chars(s)
    # Escape some characters
    @bs_escapes.keys.each_with_index do |c, i|
      s.gsub!(c, "#{EO}BSESC:#{i}#{EC}")
    end

    @cmd_escapes.keys.each_with_index do |c, i|
      s = s.gsub(Regexp.new("#{Regexp.escape(c)}([^a-zA-Z])"), "#{EO}CMESC:#{i}#{EC}" + '\1').
          gsub(Regexp.new("#{Regexp.escape(c)}\\Z"), "#{EO}CMESC:#{i}#{EC}" + '\1')
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
    result = ""
    stack = []
    i = 0

    s.each_char do |c|
      if c == "{"
        stack.push(i)
        result << "#{EO}BO:#{i}#{EC}"
        i += 1
      elsif c == "}"
        result << "#{EO}BC:#{stack.pop}#{EC}"
      else
        result << c
      end
    end

    result
  end

  def save_box(s)
    s.gsub!(/\\mbox#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/) {|m|
      s2 = $2.gsub(" ", "#{EO}SP#{EC}")
      @mbox_memory[@box_counter] = "<r>#{s2}</r>"
      ret = "#{EO}MBOX" + ("a" * @box_counter) + EC
      @box_counter += 1
      ret
    }

    s.gsub!(/\\mathit#{EO}BO:(\d+)#{EC}(.+?)#{EO}BC:\1#{EC}/) {|m|
      s2 = $2.gsub(" ", "#{EO}SP#{EC}")
      @mathit_memory[@box_counter] = "<i>#{s2}</i>"
      ret = "#{EO}MATHIT" + ("a" * @box_counter) + EC
      @box_counter += 1
      ret
    }
    s
  end

  def restore_box(s)
    s.gsub!(/[:;0-9()\[\]\{\}!,.]+/, '<r>\&</r>')

    s.gsub!(/#{EO}MBOX(a+)#{EC}/) {|m|
      @mbox_memory[$1.size]
    }

    s.gsub!(/#{EO}MATHIT(a+)#{EC}/) {|m|
      @mathit_memory[$1.size]
    }

    s.gsub('</r><r>', '').gsub('</i><i>', '').
      gsub(" ", "").gsub("#{EO}SP#{EC}", " ").
      gsub("#{EO}LT#{EC}", "&lt;").
      gsub("#{EO}GT#{EC}", "&gt;")
  end
end

class DesperaTEXFailedException < Exception
end
