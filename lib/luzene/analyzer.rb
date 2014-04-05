module Luzene
  ##
  # Query Syntax Analyzer
  #
  # The query string “mini-language” is used by the
  # Query String Query and by the q query string parameter
  # in the search API.
  #
  # The query string is parsed into a series of terms and operators.
  # A term can be a single word — quick or brown — or a phrase,
  # surrounded by double quotes — "quick brown" — which searches
  # for all the words in the phrase, in the same order..
  #

  class Analyzer
    attr_reader :scanner, :tokens

    def initialize(string)
      @string = string
      @scanner = StringScanner.new(string)
      @tokens = []
    end

    def token_patterns
      TOKEN_PATTERNS
    end

    def analyze
      until scanner.eos?
        match = token_patterns.find do |token_type, pattern|
          scanner.scan(pattern)
          create_token(token_type, scanner[1]) if scanner.matched?
        end

        scanner.clear unless match.present?
      end

      tokens
    end

    def syntax
      analyze if tokens.empty?
      tokens.map(&:syntax)
    end

    private

    def create_token(token_type, token_string)
      begin
        token_class = Object.const_get("Luzene::Token::#{ token_type.to_s.camelize }")
        tokens << token_class.new(token_string)
      rescue => e
        # Rails.logger.warn("Bad token #{ token_class } for string '#{ token_class }': #{ e }")
      end
    end
  end

end
