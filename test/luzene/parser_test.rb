require 'test_helper'

module Luzene
  class ParserTest < ActiveSupport::TestCase
    attr_reader :parser

    setup do
      @parser = Luzene::Parser.new
    end

    sample_queries(50).each do |query|
      test "#{ query } should be valid" do
        tokens = Luzene::Analyzer.new(query).analyze
        parsed = parser.parse(tokens)
        assert (parser.valid? ? parsed.present? : parsed.nil?)
      end
    end

  end
end
