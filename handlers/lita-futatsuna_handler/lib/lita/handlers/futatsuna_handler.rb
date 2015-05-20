# -*- coding: utf-8 -*-
require "mecab"
require "json"
require "yaml"

module Lita
  module Handlers
    class FutatsunaHandler < Handler
      route /二つ名(.*)/, :make_futatsuna, help: { "二つ名 foo bar" => "Makes futatsuna with foo and bar." }
      @@config = YAML.load_file('futatsuna.yml')

      def make_futatsuna(response)
        explain = true
        matches = response.matches[0][0].split(/[ 　]+/)
        matches.delete("")
        if matches.length == 0
          first = random_word_from_wikipedia[0]
          second = random_mahjong_word_from_list
          first, second = second, first if (rand(2) == 0)
        elsif matches.length == 1
          first = matches[0]
          second = random_mahjong_word_from_list
          first, second = second, first if (rand(2) == 0)
        elsif matches.length >= 2
          first = word = matches[0]
          second = word = matches[1]
          explain = false
        end
        w1 = group_by_clause(first).map(&:join)
        w2 = group_by_clause(second).map(&:join)

        w1_index = w1.size <= 2 ? 0 : rand(w1.size - 1)
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

      def random_mahjong_word_from_list
        @@config["mahjong_words_list"].sample
      end
    end
    Lita.register_handler(FutatsunaHandler)
  end
end
