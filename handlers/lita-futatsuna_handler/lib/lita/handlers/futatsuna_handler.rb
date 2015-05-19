# -*- coding: utf-8 -*-
require "mecab"

module Lita
  module Handlers
    class FutatsunaHandler < Handler
      route /二つ名[ 　]+(.+)[ 　]+(.+)/, :make_futatsuna, help: { "二つ名 foo bar" => "Makes futatsuna with foo and bar." }

      def make_futatsuna(response)
        first = word = response.matches[0][0]
        second = word = response.matches[0][1]

        w1 = group_by_clause(first).map(&:join)
        w2 = group_by_clause(second).map(&:join)

        w1_index = rand(w1.size - 1)
        w1_index = 0 if w1.size <= 2
        w2_index = rand(w2.size - 1) + 1
        w2_index = 1 if w2.size <= 2

        puts (w1[0..w1_index] + w2[w2_index..-1]).join
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
    end

    Lita.register_handler(FutatsunaHandler)
  end
end
