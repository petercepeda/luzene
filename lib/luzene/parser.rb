module Luzene
  class Parser
    attr_reader :parsed, :tokens, :errors

    def initialize(tokens = [])
      @errors = []
      @tokens = tokens
    end

    def parse(new_tokens = nil)
      errors.clear
      @tokens = new_tokens if new_tokens.present?
      @parsed = tokens.map(&:parse).join
      parsed if valid?
    end

    def valid?
      validate!
      errors.empty?
    end

    def validate!
      case
      when tokens.empty?
        errors << 'no tokens to parse'
      when parsed.blank?
        errors << 'query is invalid'
      else
        errors << 'dangling boolean operator not allowed' if dangling_boolean?
        errors << 'orphan field names not allowed' if orphan_field_name?
      end

      errors.uniq!
    end

    def dangling_boolean?
      tokens.flat_map.each_with_index.any? do |token, index|
        if token.boolean_operator?
          next_token = tokens[index + 1]
          following_token = tokens[index + 2]
          next_token.nil? || (!next_token.whitespace? && following_token.nil?)
        end
      end
    end

    def orphan_field_name?
      tokens.flat_map.each_with_index.any? do |token, index|
        if token.field_name?
          next_token = tokens[index + 1]
          next_token.nil? || next_token.whitespace?
        end
      end
    end
  end
end
