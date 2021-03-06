# -*- encoding: utf-8 -*-

require 'faraday_middleware'
require 'active_support'

module PMP
  module Connection

    ALLOWED_CONNECTION_OPTIONS = [
      :headers,
      :url,
      :params,
      :request,
      :adapter,
      :ssl,
      :oauth_token,
      :token_type,
      :basic_auth,
      :user,
      :password,
      :debug
    ].freeze

    def connection(options={})
      opts = process_options(options)
      Faraday::Connection.new(opts) do |faraday|

        add_request_auth(opts, faraday)

        [:multipart, :url_encoded].each{|mw| faraday.request(mw) }

        [:mashify, :json, :raise_error].each{|mw| faraday.response(mw) }

        faraday.response :logger if opts[:debug]

        faraday.adapter opts[:adapter]
      end
    end

    def add_request_auth(opts, faraday)
      if opts[:basic_auth] && opts[:user] && opts[:password]
        faraday.request :basic_auth, opts[:user], opts[:password]
      elsif opts[:oauth_token]
        faraday.request :authorization, opts[:token_type], opts[:oauth_token]
      end
    end

    def process_options(opts={})
      headers = opts.delete(:headers) || {}
      options = {
        :headers => {
          # generic http headers
          'User-Agent'   => opts[:user_agent],
          'Accept'       => "application/vnd.pmp.collection.doc+json",
          'Content-Type' => "application/vnd.pmp.collection.doc+json"
        },
        :ssl => {:verify => false},
        :url => opts[:endpoint]
      }.merge(opts)
      options[:headers] = options[:headers].merge(headers)

      # clean out any that don't belong
      options.select{|k,v| ALLOWED_CONNECTION_OPTIONS.include?(k.to_sym)}
    end

  end
end
