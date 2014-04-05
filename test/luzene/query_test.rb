require 'test_helper'

module Luzene
  class QueryTest < ActiveSupport::TestCase
    attr_reader :query

    setup do
      @query = Luzene::Query.new('bazinga!')
    end

    test 'should have analyzer' do
      assert_instance_of Luzene::Analyzer, query.analyzer
    end

    test 'should have parser' do
      assert_instance_of Luzene::Parser, query.parser
    end

    test 'should reassign value and update analyzer value' do
      query.value = new_query_string = 'fascinating!'
      assert_equal new_query_string, query.original
    end

    test 'should parse and return query value' do
      query.parser.stubs parse: 'bazinga!'
      assert query.query.present?
    end

  end
end
