require 'luzene/analyzer'
require 'luzene/parser'
require 'luzene/query'
require 'luzene/token'

module Luzene

  RESERVED_CHARACTERS = %w( + - && || ! ( ) { } [ ] ^ " ~ * ? : \\ / )

  # List order dependent (tokens discovered from top down)
  #
  TOKEN_PATTERNS = {
    group: /\(([^\(\)]+)\)/,
    balanced_range: /(?:\{|\[)([^{}\[\]]+(?: TO | \.{2} )[^{}\[\]]+)(?:\}|\])/,
    boolean_operator: /(AND|OR|NOT|\&{2}|\|{2}|\!)/,
    date: /(\b(?:\d{4}\/\d{1,2}\/\d{1,2}|\d{1,2}\/\d{1,2}\/\d{4})\b)/,
    field_name: /(\w+|\*):/,
    fuzzy_term: /(\w+)~/,
    phrase: /(?:"|')([^"']+)(?:"|')/,
    whitespace: /(\s+)/,
    wildcard_term: /(\w*[\?\*]\w+|\w+[\?\*]\w*|\*)/,
    regular_expression: /\/(.+?)\//,
    proximity: /~(\d+(?:\.\d+)?)/,
    range_operator: /(TO|\.{2})/,
    comparison_operator: /((?:>|<)=?)/,
    boost: /\^(\d+(?:\.\d+)?)/,
    boolean_prefix: /([+-])/,
    term: /([^\s]+)/
  }
end
