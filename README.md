# Luzene
Author: Peter Cepeda

* [Luzene Query](#luzene-query)
* [Query Syntax Analyzer](#query-syntax-analyzer)
* [Query Tokens](#query-tokens)
* [Query Parser](#query-parser)

Luzene Query
---
The search builder creates a Query object with the supplied query string:
```ruby
search = Citation.index(:pubget).search('age:23')
search.query # => #<Luzene::Query:0x00000108c2ec88...>
search.query.value # => 'age:23'
```
Though it delegates much of its functionality to an analyzer and parser, the Query object itself can be used as a String:
```ruby
query = Luzene::Query.new('cell')

query.first
  # => 'c'

query.sub(/ce/, 'ba')
  # => 'ball'

query.reverse.gsub(/(\w)\1/, \1)
  # => 'lab'
```

Query Syntax Analyzer
---
The query string is parsed into a tokens, a series of terms and operators, by the Analyzer class using a scanner and token definitions:
```ruby
query = Luzene::Query.new('(cat AND dog) OR mouse:mighty [2013/01/01 TO 2013/12/31] +kraken')

query.analyze
  # => [#<Luzene::Token::Group:0x000001027e5858...>, ...]

query.syntax
  # => [{:group=>
  #      [:term, :whitespace, :boolean_operator, :whitespace, :term]},
  #      :whitespace,
  #      :boolean_operator,
  #      :whitespace,
  #      :field_name,
  #      :term,
  #      :whitespace,
  #      {:balanced_range=>
  #      [:date, :whitespace, :range_operator, :whitespace, :date]},
  #      :whitespace,
  #      :boolean_prefix,
  #      :term]
```

Query Tokens
---
Tokens can be either a Literal or Composite. Literal tokens represent the simplest parts of a query like words, phrases, numbers, etc. Composite tokens are made up of other composite and literal tokens.

Tokens include Group, BalancedRange, BooleanOperator, Date, FieldName, FuzzyTerm, Phrase, Whitespace, WildcardTerm, RegularExpression, Proximity, RangeOperator, ComparisonOperator, Boost, BooleanPrefix, and Term
```ruby
token = Luzene::Token::Term.new('pet')
  # => #<Luzene::Token::Term:0x00000106a18dd8 @value="pet">

token.type    # => :term
token.syntax  # => :term
token.parse   # => "pet"

token = Luzene::Token::Group.new('dog AND cat')

token.type
  # => :group

token.tokens
  # => [#<Luzene::Token::Term:0x000001027e5858...>, ...]

token.syntax
  # => [:term, :whitespace, :boolean_operator, :whitespace, :term]

token.parse
  # => "(dog AND cat)"
```
All tokens know their type, syntax and how to properly parse themselves. Composite tokens have the added ability to analyze its values and house tokens themselves.

Query Parser
---
The parser creates a string out of the tokens generated from the analyzer and validates the string generated.
```ruby
parser = Luzene::Parser.new
  # => #<Luzene::Parser:0x0000010a00c070...>
parser.parse(query.tokens)
  # => "(cat AND dog) OR mouse:mighty [2013/01/01 TO 2013/12/31] +kraken"
parser.valid? # => true
parser.errors # => []
```
