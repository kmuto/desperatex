# DesperaTEX - 無茶しやがってっく

Copyright 2015 Kenshi Muto

DesperaTEX は、TeX の数式ソースを HTML 表現にする低機能かつ力技な
Ruby ライブラリです。

Web ブラウザ上の表現においては、MathML や MathJax を使うほうが適切ですが、
EPUB リーダーのように、オフライン動作・JavaScript 実行禁止・MathML サポートも
イマイチ という過渡期の状況においては、ある程度役立つ可能性があります。

利用可能な TeX 数式は HTML で簡易に表現可能なもののみに制約されます
(書体・上付き・下付き・いくつかの記号)。
Σや√などの表現はできませんので、そのような箇所はあきらめて画像にするのが
よいでしょう。

## セットアップ

desperatex.rb を適当な場所に置き、require でそれを参照するだけです。

## 例
sample/desperatex-test.rb にサンプルがあります。
実行すると、desperatex-test.html ファイルができあがります。

```
cd sample
./desperatex-test.rb
```

## 機能説明
```
new(代替マップファイル名=nil)
```

DesperaTEX クラスはインスタンス化して利用します。
「代替マップファイル名」にファイルを指定すると、そのファイルを
代替マップファイルとします。

代替マップファイルは「元文字列 タブ 変換後文字列」の形式で、
「#@#」で始まる行はコメントとして無視されます。

```
parse(文字列)
```

指定の文字列を簡易 HTML 記法に変換して返します。
変換できなかった場合、DesperaTEXFailedException 例外を投げます。

インスタンス化時に代替マップファイルが指定されていて、その中の
「元文字列」と parse に指定された文字列が一致する場合には、解析は
せずに直ちに代替マップファイルの「変換後文字列」を返します。

```
tohtml(文字列)
```

簡易 HTML 記法から正当な HTML 記法に変換します。
具体的には```<r></r>``` → ```<span class='math-normal'></span>```、
```<rvbar></rvbar>``` → ```<span class='math-normal'></span>```、
```<ibar></ibar>``` → ```<span class='math-italic-topbar'></span>```
を行うだけです。

## InDesign
```
toindesign(文字列)
```

簡易 HTML 記法から InDesign XML に変換します。

- 2重を超える上付き・下付きはエラーになります。
- 上付き・下付きで TeX 命令を添字にする場合、`a_\alpha` ではなく `a_{\alpha}` のように囲む必要があります。

XML タグとマッピングすべき文字スタイル
```
i: イタリック
b: 太字イタリック
sup2: 上付きの上付き、イタリック
bsup2: 上付きの上付き、太字イタリック
supsub: 上付きの下付き、イタリック
bsupsub: 上付きの下付き、太字イタリック
sub2: 下付きの下付き、イタリック
bsub2: 下付きの下付き、太字イタリック
subsup: 下付きの上付き、イタリック
bsubsup: 下付きの上付き、太字イタリック
sub: 下付き、イタリック
bsub: 下付き、太字イタリック
sup: 上付き、イタリック
bsup: 上付き、太字イタリック
r: 正体
br: 太字正体
rsup2: 上付きの上付き、正体
rbsup2: 上付きの上付き、太字正体
rsupsub: 上付きの下付き、正体
rbsupsub: 上付きの下付き、太字正体
rsub2: 下付きの下付き、正体
rbsub2: 下付きの下付き、太字正体
rsubsup: 下付きの上付き、正体
rbsubsup: 下付きの上付き、太字正体
rsub: 下付き、正体
rbsub: 下付き、太字正体
rsup: 上付き、正体
rbsup: 上付き、太字正体
```

## Copyright & License
```
 Copyright (c) 2015 Kenshi Muto.
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. Neither the name of the University nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.
```
