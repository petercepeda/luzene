require 'chronic'

module Luzene
  module Token
    ##
    # Tokens
    #
    # Tokens can be either a Literal or Composite
    # Literal tokens represent the simplest parts of a query
    # like words, phrases, numbers, etc.
    #
    # Composite tokens are made up of other composite and
    # literal tokens.
    #
    class Literal
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def type
        self.class.name.demodulize.underscore.to_sym
      end

      def type?( type_name )
        type == type_name.to_sym
      end

      alias_method :syntax, :type

      def parse
        @value.gsub(reserved_regexp) { |match| '\\' + match }
      end

      def reserved_characters
        Luzene::RESERVED_CHARACTERS
      end

      def reserved_regexp
        Regexp.union reserved_characters
      end

      def method_missing(action, *args, &block)
        token_types = Luzene::TOKEN_PATTERNS.keys.map(&:to_s)
        if (type = action.to_s.gsub('?', '')) && token_types.include?(type)
          type?(type)
        else
          super
        end
      end
    end

    class Composite < Literal
      attr_reader :analyzer, :tokens

      def initialize(value)
        super
        @analyzer = Luzene::Analyzer.new(value)
        @tokens = @analyzer.analyze
      end

      def syntax
        { type => tokens.map(&:syntax) }
      end

      def parse
        tokens.map(&:parse).join
      end
    end

    ##
    # Token types
    #
    # Each token type is taken directly from Elasticsearch
    # supported query syntax documentation and correllates with
    # recent version of Lucene syntax
    #

    class Term < Token::Literal
    end

    class Phrase < Token::Literal
      def parse
        '"%s"' % super
      end
    end

    class Whitespace < Token::Literal
      def parse
        ' '
      end
    end

    # Field Names
    #
    # As mentioned in Query String Query, the default_field is
    # searched for the search terms, but it is possible to
    # specify other fields in the query syntax:
    #
    # where the status field contains active
    # e.g. status:active
    #
    # where the title field contains quick or brown
    # e.g. title:(quick brown)
    #
    # where the author field contains the exact phrase "john smith"
    # e.g. author:"John Smith"
    #
    # where any of the fields book.title, book.content or
    # book.date contains quick or brown (note how we need to
    # escape the * with a backslash):
    # book.\*:(quick brown)
    #
    # where the field title has no value (or is missing):
    # e.g. _missing_:title
    #
    # where the field title has any non-null value:
    # e.g. _exists_:title
    #
    class FieldName < Token::Literal
      def parse
        '%s:' % super # check format
      end
    end

    # Wildcards
    #
    # Wildcard searches can be run on individual terms,
    # using ? to replace a single character, and * to
    # replace zero or more characters:
    # e.g. qu?ck bro*
    #
    # Be aware that wildcard queries can use an enormous amount
    # of memory and perform very badly — just think how many terms
    # need to be queried to match the query string "a* b* c*".
    #
    class WildcardTerm < Token::Literal
      def reserved_characters
        super - %w( * ? )
      end
    end

    # Regular Expressions
    #
    # Regular expression patterns can be embedded in the
    # query string by wrapping them in forward-slashes ("/"):
    # e.g. name:/joh?n(ath[oa]n)/
    #
    class RegularExpression < Token::Literal
      def parse
        '/%s/' % @value
      end
    end

    # Fuzziness
    #
    # We can search for terms that are similar to, but not exactly
    # like our search terms, using the “fuzzy” operator:
    # e.g. quikc~ brwn~ foks~
    #
    class FuzzyTerm < Token::Literal
      def reserved_characters
        super - %w( ~ )
      end
    end

    # Proximity Searches
    #
    # While a phrase query (eg "john smith") expects all of the terms
    # in exactly the same order, a proximity query allows the specified
    # words to be further apart or in a different order. In the same
    # way that fuzzy queries can specify a maximum edit distance for
    # characters in a word, a proximity search allows us to specify a
    # maximum edit distance of words in a phrase:
    # e.g. "fox quick"~5
    #
    class Proximity < Token::Literal
      def parse
        '~%s' % super if @value.to_i > 0
      end
    end

    # Ranges
    #
    # Ranges can be specified for date, numeric or string fields.
    # Inclusive ranges are specified with square brackets [min TO max]
    # and exclusive ranges with curly brackets {min TO max}.

    # All days in 2012:
    # e.g. date:[2012/01/01 TO 2012/12/31]
    Date::DATE_FORMATS[:short_slash] = '%Y/%m/%d'

    class Date < Token::Literal
      def parse
        Chronic.parse(@value).to_date.to_formatted_s(:short_slash)
      end
    end

    # Numbers 1..5
    # e.g. count:[1 TO 5]

    # Tags between alpha and omega, excluding alpha and omega:
    # e.g. tag:{alpha TO omega}

    # Numbers from 10 upwards
    # e.g. count:[10 TO *]

    # Dates before 2012
    # e.g. date:{* TO 2012/01/01}
    #

    # Curly and square brackets can be combined:
    #
    # Numbers from 1 up to but not including 5
    # e.g. count:[1 .. 5}
    #
    class BalancedRange < Token::Composite
      def parse
        '[%s]' % super if (tokens.count == 3 && tokens[1].range_operator?) || (tokens.count == 5 && tokens[2].range_operator?)
      end
    end

    class RangeOperator < Token::Literal
      def parse
        'TO'
      end
    end

    # Ranges with one side unbounded can use the following syntax:
    # e.g.
    # age:>10
    # age:>=10
    # age:<10
    # age:<=10

    # Note
    # To combine an upper and lower bound with the simplified syntax,
    # you would need to join two clauses with an AND operator:
    # e.g.
    # age:(>=10 AND < 20)
    # age:(+>=10 +<20)
    #
    class ComparisonOperator < Token::Literal
      def parse
        super if %w( > >= < <= ).include?(@value)
      end
    end

    # Boosting
    #
    # Use the boost operator ^ to make one term more relevant
    # than another. For instance, if we want to find all documents
    # about foxes, but we are especially interested in quick foxes:
    # e.g. quick^2 fox
    #
    # The default boost value is 1, but can be any positive floating
    # point number. Boosts between 0 and 1 reduce relevance.
    #
    # Boosts can also be applied to phrases or to groups:
    # e.g. "john smith"^2   (foo bar)^4
    #
    class Boost < Token::Literal
      def parse
        '^%s' % super if @value.to_i > 0
      end
    end

    # Boolean Operators
    #
    # By default, all terms are optional, as long as one term matches.
    # A search for foo bar baz will find any document that contains
    # one or more of foo or bar or baz. We have already discussed the
    # default_operator above which allows you to force all terms to be
    # required, but there are also boolean operators which can be used
    # in the query string itself to provide more control.
    #
    # The preferred operators are + (this term must be present)
    # and - (this term must not be present). All other terms are
    # optional. For example, this query:
    #
    # e.g. quick brown +fox -news
    #
    # states that:
    #
    # fox must be present
    # news must not be present
    # quick and brown are optional — their presence increases the
    # relevance
    #
    # The familiar operators AND, OR and NOT (also written &&, || and !) are also supported. However, the effects of these operators can be more complicated than is obvious at first glance. NOT takes precedence over AND, which takes precedence over OR. While the + and - only affect the term to the right of the operator, AND and OR can affect the terms to the left and right.
    #
    # Rewriting the above query using AND, OR and NOT demonstrates
    # the complexity:
    #
    # e.g. quick OR brown AND fox AND NOT news
    #
    # This is incorrect, because brown is now a required term.
    #
    class BooleanPrefix < Token::Literal
      def parse
        @value if %w( + - ).include?(@value)
      end
    end

    class BooleanOperator < Token::Literal
      def parse
        @value if %w( AND OR NOT && || ! ).include?(@value)
      end
    end

    # Grouping
    #
    # Multiple terms or clauses can be grouped together with
    # parentheses, to form sub-queries:
    #
    # e.g. (quick OR brown) AND fox
    #
    # Groups can be used to target a particular field, or to boost
    # the result of a sub-query:
    #
    # e.g. status:(active OR pending) title:(full text search)^2
    #
    class Group < Token::Composite
      def parse
        '(%s)' % super
      end
    end

    # Reserved Characters
    #
    # If you need to use any of the characters which function
    # as operators in your query itself (and not as operators),
    # then you should escape them with a leading backslash.
    # For instance, to search for (1+1)=2, you would need
    # to write your query as \(1\+1\)=2.
    #
    # The reserved characters are:
    # + - && || ! ( ) { } [ ] ^ " ~ * ? : \ /
    #
    # Failing to escape these special characters correctly
    # could lead to a syntax error which prevents your
    # query from running.
    #

  end
end
