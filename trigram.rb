#!/usr/bin/ruby
# coding: utf-8
require 'pp'
# TriGramによる類似度の比較
#   opt  ignore:      比較にあたって無視する文字 default ",\"'\s　"
#        part_size:   比較にあたって使う文字数　 default 3
#
# 入り口でごちょごちょ行って other のTriGramをOtherにもたせているのは
# 文字列群 と 文字列群 を比較する場合ための高速化のお手軽工夫です。
# 文字列群をメモリ上に取り込まないと高速化できないので、多すぎる比較の場合に
# 破綻するかも。
class String
  TrigramSize = 3
  def trigram(other,opt = {})
    @other = other
    @other.tricount opt
    common_gram_size * 100/ total_gram_size
  end
  def common_gram_size
    (tricount.keys & @other.tricount.keys).
      inject(0){|s,gram| s + [tricount[gram],@other.tricount[gram]].min}
  end
  def total_gram_size
    (tricount.keys | @other.tricount.keys).
      inject(0){|s,gram| s + [tricount[gram],@other.tricount[gram]].max}
  end
           
  def tricount(opt = {})
    return @tricount if @tricount
    
    opt = {ignore: ",\"'\s　",part_size: 3}.merge opt
    ignore = %r([#{opt[:ignore]}]+)
    part_size = opt[:part_size]
    source = self.gsub(ignore, "")
    @tricount = (0..(source.size - part_size )).
                  map{|start| source[start,part_size] }.
                  group_by{|part| part }.
                  map{|part,ary| [part,ary.size]}.to_h
    @tricount.default = 0
    @tricount
  end
end
__END__
TriGramを使った文字列の類似度を求める必要が出てきて調べてみたのですが、net上に色々ソースが提供されていますがその結果が一致しないのです。
詳しく見てみると
　TriGramの中に同じものが出てこない場合は良いが、同じものが出てきた場合に数え方が異なっている
　ものによっては、対称でない
    対称とは　文字列Aと文字列Bを比べても、BとAを比べても 同じになるはずがならないものもある。
rubyで３つ、PHPで2つ、perlで一つ見つけましたが
　a="AとBを比べても、BとAを比べても"
　b="BとAを比べても、AとBを比べても"
で調べた結果が下です。

複数回出てくることを考慮すると
分子：共通して存在するTriGramの数。重複する場合は重複した数(少ない方）
分母：全体のTriGramの数。ただし共通しているものはダブルカウントしない(多い方の数）
「整数の世界」的表現をすると　分子は最大公約数、分母は最小公倍数　となるのでは？

その考え方で作られていると思われるものは本methodの他に(4)と(6)が有りましたが、各々少しずつ問題がありました。
(6)のrubyは分子のカウントに　Arrayの&演算を使っていますが、これは重複する要素は取り除かれるため少なくなってしまいます。
　また分母のカウントに　(Array+Array).uniq を使っているためやはり重複している要素があると数が変わります。
(4)のPHPは分子のカウントにarray_intersectを使っています。これはrubyの & と違って重複を残すので
数は合うのですが、もとになるTrigramのとり方に間違いあが有りました。文末の2文字、1文字もTriGramとして取り込んでいました。
(5)のperlはどこに問題があるか読みきれませんでした。4から5になる時にrubyに浮気したつけが今でてきました。

              |本method |  (1)|  (2)| (3)| (4)| (5)|(6)
        a   b |分子 分母|     |     |    |    |    |
AとB    1   1 | 1  　 1 | 1  1| 1  1|    |    |    |
とBを   1   1 | 1     1 | 1  1| 1  1|    |    |    |
Bを比   1   1 | 1     1 | 1  1| 1  1|    |    |    |
を比べ  2   2 | 2     2 | 4  4| 1  1|    |    |    |
比べて  2   2 | 2     2 | 4  4| 1  1|    |    |    |
べても  2   2 | 2     2 | 4  4| 1  1|    |    |    |
ても、  1   1 | 1     1 | 1  1| 1  1|    |    |    |
BとA    1   1 | 1     1 | 1  1| 1  1|    |    |    |
とAを   1   1 | 1     1 | 1  1| 1  1|    |    |    |
Aを比   1   1 | 1     1 | 1  1| 1  1|    |    |    |
も、B   1     | 0     1 |    1|    1|    |    |    |
、Bと   1     | 0     1 |    1|    1|    |    |    |
も、A       1 | 0     1 |     |     |    |    |    |
、Aと       1 | 0     1 |     |     |    |    |    |
--------------+---------+-----+-----+----+----+----+
  計          | 13    17|19 21|10 14| - -|15 17|   |10 14 
類似度        |       76|   94|   71| 47 |   88| 65|   71
              | 本method|  (1)|  (2)| (3)| (4) |(5)   (6)
a="AとBを比べても、BとAを比べても"
b="BとAを比べても、AとBを比べても"

(1) http://freestyle.nvo.jp/archives/919　 ruby
(2) https://github.com/milk1000cc/trigram  ruby
(3) PHP similar_text
(4) http://www.pahoo.org/e-soul/webtech/php03/php03-06-01.shtm
(5) http://cpansearch.perl.org/src/TAREKA/String-Trigram-0.12/Trigram.pm
(6) http://www.mk-mode.com/octopress/2016/03/25/ruby-check-string-similarity-by-ngram/

                                                                                
