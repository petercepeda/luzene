require 'test_helper'

module Luzene
  class AnalyzerTest < ActiveSupport::TestCase
    attr_reader :analyzer

    setup do
      query = '(cat AND dog) OR mouse:mighty [2013/01/01 TO 2013/12/31] +kraken'
      @analyzer = Luzene::Analyzer.new(query)
    end

    test 'should return list of token patterns' do
      assert analyzer.token_patterns.include?(:term)
    end

    test 'should return list of tokens' do
      assert_kind_of Luzene::Token::Composite, analyzer.analyze.first
    end

    test 'should return syntax of analyzed query' do
      expected_syntax =
      [
        { group: [:term, :whitespace, :boolean_operator, :whitespace, :term] },
        :whitespace,
        :boolean_operator,
        :whitespace,
        :field_name,
        :term,
        :whitespace,
        { balanced_range:[:date, :whitespace, :range_operator, :whitespace, :date] },
        :whitespace,
        :boolean_prefix,
        :term
      ]
      assert_equal expected_syntax, analyzer.syntax
    end

  end
end
