module Luzene
  class Query
    attr_reader :original, :parser

    delegate :analyze, :syntax, :tokens, to: :analyzer
    delegate :parse, :errors, :valid?, to: :parser
    delegate :to_s, :to_str, to: :query

    alias_method :tokens, :analyze

    def initialize(query_string)
      @original = query_string
      @parser = Luzene::Parser.new
    end

    def analyzer
      Luzene::Analyzer.new(original)
    end

    def value=(query_string)
      @original = query_string
    end

    def query
      parse(tokens)
    end

    alias_method :value, :query
  end
end
