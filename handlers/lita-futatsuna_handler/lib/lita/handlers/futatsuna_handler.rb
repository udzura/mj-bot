# -*- coding: utf-8 -*-
require "mecab"
require "json"

module Lita
  module Handlers
    class FutatsunaHandler < Handler
      route /二つ名(.*)/, :make_futatsuna, help: { "二つ名 foo bar" => "Makes futatsuna with foo and bar." }

      def make_futatsuna(response)
        explain = true
        matches = response.matches[0][0].split(/[ 　]+/)
        matches.shift
        matches.delete(nil)
        if matches.length == 0
          first = word = random_word_from_wikipedia[0]
          second = word = mahjong_word_from_wikipedia
          first, second = second, first if (rand(2) == 0)
        elsif matches.length == 1
          first = word = matches[0]
          second = word = mahjong_word_from_wikipedia
          first, second = second, first if (rand(2) == 0)
        elsif matches.length >= 2
          first = word = matches[0]
          second = word = matches[1]
          explain = false
        end
        w1 = group_by_clause(first).map(&:join)
        w2 = group_by_clause(second).map(&:join)

        w1_index = w1.size <= 2 ? 0 :  rand(w1.size - 1)
        w2_index = w2.size <= 2 ? w2.size - 1 : rand(w2.size - 1)

        response.reply (w1[0..w1_index] + w2[w2_index..-1]).join
        response.reply ("( #{first} + #{second} )") if explain
      end

      class Word < Struct.new(:word, :parts)
        def ancillary?
          parts[0] == "助詞" or parts[0] == "助動詞"
        end

        def suffix?
          parts[0] == "名詞" && parts[1] == "接尾"
        end

        def prefix?
          parts[0] == "接頭詞"
        end

        def independent?
          !ancillary? and !suffix?
        end

        def to_s
          word.to_s
        end
      end

      private
      def make_words(sentence)
        tagger = MeCab::Tagger.new
        tagger.parse(sentence)
          .split("\n")
          .map{|v| v.split("\t") }
          .map{|(word, meta)|
          if meta
            Word.new(word, meta.split(","))
          else
            nil
          end
        }
      end

      def group_by_clause(sentence)
        w = make_words(sentence)
        a = []
        tmp = []
        w.each_cons(2) do |w1, w2|
          tmp << w1
          if !w2 or (w2.independent? && !w1.prefix?)
            a << tmp
            tmp = []
          end
        end

        return a
      end

      def random_word_from_wikipedia(num=1)
        uri = URI.parse("http://ja.wikipedia.org/w/api.php?action=query&format=json&rnnamespace=0&list=random&rnlimit=#{num}")
        json = Net::HTTP.get(uri)
        result = JSON.parse(json)["query"]["random"].map{|a| a["title"].force_encoding("utf-8")}
      end

      def mahjong_word_from_wikipedia
        %w(間四間 アウト 青天井 赤五 赤牌 和了り 和了り牌 和了り放棄 和了り役 和了りやめ 亜空間 足止め立直 頭 頭ハネ 当たり 当たり牌 アツシボ 後付け 後引っ掛け 有り有り アリス アルシーアル 荒れ場 合わせ打ち 暗槓 暗刻 暗刻落とし 安全牌 安牌 一向聴 一荘 一荘戦 一飜縛り 如何様 如何様師 イチゴー 一コロ イチサン 一鳴き 一鳴き聴牌 イチロク 一本場 インパチ ウーピン 浮き 右10 打ち筋 打つ 右2 馬 裏 裏筋 裏ドラ 裏目 右6 上自摸 Aトップ 絵合わせ エレベーター オーラス 丘 オカルト 置きザイ 送り槓 送り込み 押さえる オタ 客風 追っかけ立直 落とす おな聴 お化け お引き オモ 表ドラ 親 親っ被り 親ッ跳 親流れ 親倍 親倍 親リー 降りる 開門 カウント 返り東 風牌 片和了り かっぱぎ 被る 壁 上家 鴨 空切り 空聴 空鳴き 仮々東 仮聴 仮東 河 槓 槓裏 完先 完全先付け 嵌搭 嵌張 嵌張待ち 槓子 槓ドラ ガン牌 槓振り 危険牌 基本符 決め打ち 逆切り 逆モーション キャタピラ ギャル雀 九種九牌 九種九牌倒牌 供託棒 ギリ師 切る 食い替え 食い下がり 食い仕掛け 食い断 食い取り 食い流れ 食う 空槓 空吃 空ポン 下りポン くっつき聴牌 くるくるチャンス クンロク 形式聴牌 形聴 原点 現物 元禄積み 子 刻子 客風牌 交通事故 腰 誤吃 ゴットー ゴッパ 誤ツモ 小手返し 事師 小場 誤ポン ゴミ 誤ロン ゴンニー コンビ打ち 先切り 先付け 先自摸 左4 差し馬 差し込み サバゴボ 様 様師 晒す ザンク 三元牌 三コロ 散家 三家和 ザンニー 三抜け 三倍満 サンピン 三麻 三面張 三面待ち Cトップ 洗牌 仕掛ける 自風 自9 自5 地獄待ち 沈み 下自摸 字牌 柴棒 自風牌 絞る 下家 西家 西入 西場 シャボ待ち 邪魔ポン 三味 三味線 雀頭 双ポン待ち 数牌 順位馬 純空 順子 順子場 少牌 小明槓 生牌 ションベン 四開槓 四槓流れ 四喜牌 四風子連打 四風連打 スカート捲り 筋 筋引っ掛け 捨て牌 スポーツ麻雀 スリーラン 責任払い セット セット雀荘 セット卓 攻める 全自動卓 全ツッパ 全山 索子 即ヅモ 即リー 外馬 側聴・傍聴 染める 他家 搭子 多牌 代打ち 代走 大明槓 高め タッパイ 種銭 打牌 ダブ東 ダブ南 ダブリー ダブル ダブル役満 ダブロン 黙聴 多面張 多面待ち 単騎待ち 断トツ タンピン 断ラス 吃 起家 起家マーク 吃聴 チッチー 千鳥積み 茶殻 加槓 荘家 荘風牌 中張牌 籌馬 チョンチョン 錯和・沖和 チンマイ 字牌 突っ張る 燕返し 積み棒 ツメシボ 自摸 自摸和了り 自摸切り 自摸符 自摸和 吊り芸 出和了り デカピン デカリャンピン 出禁 デジタル 手出し 鉄砲 徹麻 手なり 手の内 手牌 デバサイ 手役 寺銭 点一 点五 点三 点二 聴牌 点パネ 点一 点棒 対3 対7 対11 対死 対子 対子落とし 対子場 対7 対面 通し 通らば 途中流局 特急券 トッパン トップ ドボン トマト ドラ ドラ爆 ドラ爆弾 ドラ表示牌 ドラ含み ドラまたぎ トリプル トリプル役満 トリプルロン トリロン 幢 東返り 東家 東南戦 東場 東風戦 中抜き 流れ 流れる 鳴き断 鳴く ナシ 無し無し ナナトーサン ナナナナ 南家 南入 南場 ニーヨン ニーヨンマル 握り 握り込み 二コロ ニック 二鳴き 二抜け 二の二の天和 ニンロク 抜きドラ 抜け番 不聴 不聴罰符 不聴立直 ノーレート 延べ単 ノーチャンス ノー和了 のみ のみキック 配給原点 配原 牌効率 海底牌 配牌 白板 牌譜 倍満 牌山 入り目 包 場風 場決め 箱点 場ゾロ 裸単騎 バッタ 罰符 花牌 跳満 場風牌 飜 半自動卓 半荘 半荘戦 バンバン Bトップ 引き 左12 左8 左4 引っ掛け 拾い 筒子 平局 ピンヅモ ピンピンロク 符 ブー麻雀 ブーマン 副露 副底 飜牌 風速 風牌 ブッコ抜き ブットビ 符ハネ ブラフ フリー雀荘 フリー卓 振り込み 振聴 振聴立直 北家 北場 ベタ降り ベタ師 辺搭 辺張待ち 河 河底牌 和了 放銃 棒聴 暴牌 荒牌 ポン ポンかす 紅中 ポン聴 紛れ またぎ筋 回す 満貫 満州 萬子 満直 見え見え 見送る 右10 右2 右6 見せ牌 見逃す 明槓 明刻 迷彩 門前 門前加符 門前役 メンチン 面子 メンピン 門風牌 メンホン メンタンピン 摸打 盲牌 持ち持ち モロ引っ掛け ヤオ九牌 焼き鳥 焼き豚 役 役牌 役満 安め 山 山越し 闇聴 ヨンパー ラス ラス親 ラス確 ラス半 ラス前 リー即 立直宣言牌 立直棒 リーヅモ 理牌 両嵌 リャンシバ 二飜縛り 緑發 流局 両面単騎 両面待ち リャンピン 嶺上牌 レート 連荘 連風牌 老頭牌 六枚切り ロクヨン ロッケー 六間積み 栄 栄和了り 栄和 割れ目 萬子 ワンチャンス ワンツー 王牌).sample
      end
    end
    Lita.register_handler(FutatsunaHandler)
  end
end
