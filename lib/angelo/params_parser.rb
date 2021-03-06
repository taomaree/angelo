require 'cgi'

module Angelo

  class FormEncodingError < StandardError; end

  module ParamsParser

    EMPTY_JSON = '{}'
    SEMICOLON = ';'
    EQUALS = '='
    AMPERSAND = '&'

    def parse_formencoded str
      raise FormEncodingError unless str.empty? or str.index EQUALS
      str.split(AMPERSAND).reduce(Responder.symhash) do |p, kv|
        key, value = kv.split(EQUALS).map {|s| CGI.unescape s}
        p[key] = value
        p
      end
    end

    def parse_query_string
      parse_formencoded(request.query_string || '')
    end

    def parse_post_body
      body = request.body.to_s
      qs = parse_query_string
      case
      when form_encoded?
        body = parse_formencoded body
        qs.merge! body
      when json?
        body = EMPTY_JSON if body.empty?
        body = JSON.parse body
        recurse_symhash qs.merge! body
      else
        qs
      end
    end

    def recurse_symhash h
      h.each do |k,v|
        if Hash === v
          h[k] = Responder.symhash.merge! v
          recurse_symhash h[k]
        end
      end
      h
    end

    def form_encoded?
      content_type? FORM_TYPE
    end

    def json?
      content_type? JSON_TYPE
    end

    def content_type? type
      if request.headers[CONTENT_TYPE_HEADER_KEY]
        request.headers[CONTENT_TYPE_HEADER_KEY].split(SEMICOLON).include? type
      else
        nil
      end
    end

  end

end
