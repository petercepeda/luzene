module LuzeneTestHelper
  extend ActiveSupport::Concern

  TOKEN_TYPES_AND_VALUES = {
    literal: 'dog',
    composite: '(dog cat)',
    term: ['cat?', 'cat\?'],
    phrase: ['dog cat', '"dog cat"'],
    whitespace: ['         ', ' '],
    field_name: ['mouse', 'mouse:'],
    wildcard_term: ['fox*', 'fox*'],
    regular_expression: ['joh?n(ath[oa]n)', '/joh?n(ath[oa]n)/'],
    fuzzy_term: ['cow~', 'cow~'],
    proximity: ['5', '~5'],
    date: ['01/25/1979', '1979/01/25'],
    balanced_range: ['1 .. 5', '[1 TO 5]'],
    range_operator: ['..', 'TO'],
    comparison_operator: ['>=', '>='],
    boost: ['2', '^2'],
    boolean_prefix: ['+', '+'],
    boolean_operator: ['AND', 'AND'],
    group: ['dog cat', '(dog cat)']
  }

  QUERY_SAMPLES = [
    'bird',
    '"brown cow"',
    'animal:fox',
    'mouse:"Mighty Mouse"',
    '*:*',
    'age:20*',
    'NOT',
    '(fish OR turtle)',
    '/(horse|mare)s?/',
    'dog~',
    '[1/25/2014 TO 3/25/2014]',
    'type:(predator)',
    '"kitty cat"~5',
    'height:(+>=10 +<20)',
    'mammal^4',
    'dinosaur!',
    '1 .. 10',
    '[100 .. 1000]',
    'date:[1/1 .. 12/31]',
    '||',
    'pony &&',
    'kingdom:'
  ]

  def assert_token(type, value, expected_value = nil)
    # Create token, get type, and template fail message
    token = self.class.token(type, value)
    message = "#{ token.class.name } token invalid:"

    # Test methods inherited from Token::Literal
    assert_equal type, token.type, message + 'incorrect type'
    assert token.type?(type), message + 'should match type'
    assert token.syntax.present?
    assert_not_nil token.parse, message + 'parse should return a value'
    assert token.reserved_characters.any?
    assert_instance_of Regexp, token.reserved_regexp

    # Test magic type check methods e.g. whitespace? => type?(:whitespace)
    unless [:literal, :composite].include?(type)
      assert token.send("#{ type }?"), message + 'should send magic method to type?'
    end

    # Test Token::Composite specific methods
    if token.kind_of? Luzene::Token::Composite
      assert_instance_of Luzene::Analyzer, token.analyzer, 'should have analyzer'
      assert token.tokens.respond_to?(:each), 'should have own collection of tokens'
    end

    # Test expected parsed value
    assert_equal expected_value, token.parse, message + 'should equal expected value' if expected_value
  end

  module ClassMethods
    def token_types_and_values
      TOKEN_TYPES_AND_VALUES
    end

    def token(type, value)
      "Luzene::Token::#{ type.to_s.camelize }".constantize.new value
    end

    def tokens
      token_types_and_values.map { |type, values| token(type, [*values].first) }
    end

    def sample_query
      QUERY_SAMPLES.sample(3).join(' ')
    end

    def sample_queries(count = 10)
      (count * 1.5).to_i.times.map { sample_query }.uniq.first(count)
    end
  end

end
