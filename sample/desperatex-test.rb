#!/usr/bin/env ruby
# coding: utf-8
require '../desperatex.rb'
tests = <<'EOT'
(x_{n}x_{n-1}\cdots x_{0})_{b}
\mbox{a and b 1}
\mathit{feed}
(-2) + (-3)
(00010)_{one} + (11110)_{two} = (00000)_{three}
(xxx,n)
(y+2^j)^2
-2^{n-1}
0 \leq a \leq 1023, 0 \leq b \leq 255
1=白黒
1=\mbox{白黒}
O(n^2)
\bar{x}
\bar{x}y\bar{z}
a < b/dy
a > b/dy
val\mbox{\%}64
f(x,y)
f(x,y)=1
k= \log_2 m
k= \log_n m
k= \log m
z=f_i(x,y)
EOT

html = []
d = DesperaTEX.new
tests.each_line do |l|
  l.chomp!
  begin
    html.push(d.tohtml(d.parse(l)))
  rescue DesperaTEXFailedException => e
    STDERR.puts "Error! #{e}"
  end
end

File.open("desperatex-test.html", "w") do |f|
  f.puts <<EOT
<html>
<head>
<meta charset="UTF-8" />
<link rel="stylesheet" href="desperatex.css" type="text/css" />
</head>
<body>
<ul>
EOT

  f.puts html.map {|item|
    "<li><span class=\"equation\">#{item}</span></li>\n"
  }.join
  
  f.puts <<EOT
</ul>
</body>
</html>
EOT
end
