# -*- coding: utf-8 -*-
require "mecab"
require "json"

module Lita
  module Handlers
    class FutatsunaHandler < Handler
      route /二つ名(.*)/, :make_futatsuna, help: { "二つ名 foo bar" => "Makes futatsuna with foo and bar." }

      def make_futatsuna(response)
        explain = true
        matches = response.matches[0][0].split(/[ 　]/)
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

        w1_index = rand(w1.size - 1)
        w1_index = 0 if w1.size <= 2
        w2_index = rand(w2.size - 1) + 1
        w2_index = 1 if w2.size <= 2

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
        uri = URI.parse("http://tools.wmflabs.org/erwin85/randomarticle.php?lang=ja&family=wikipedia&categories=%E9%BA%BB%E9%9B%80&namespaces=0&subcats=1&d=9")
        res = Net::HTTP.get_response(uri)
        res = Net::HTTP.get(URI.parse('http:' + res['location'].gsub("w/index.php?title=:", "wiki/")))
        res =~ /<title>(.+)<\/title>/
        $1.to_s.gsub(/ \- Wikipedia$/, '').force_encoding("utf-8")
      end
    end

    Lita.register_handler(FutatsunaHandler)
  end
end
