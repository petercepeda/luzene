require 'test_helper'

module Luzene
  class TokenTest < ActiveSupport::TestCase

    token_types_and_values.each do |type, args|
      test "#{ type } token" do
        assert_token type, *args
      end
    end

  end
end
