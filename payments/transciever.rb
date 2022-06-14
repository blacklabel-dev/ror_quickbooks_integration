# frozen_string_literal: true

module Quickbooks
  module Payments
    class Transciever
      def initialize
        @connection = Faraday.new(url: @base_url) do |faraday|
          faraday.response :logger
          faraday.headers['Content-Type'] = 'application/json'
          faraday.headers['Accept'] = 'application/json'
          faraday.headers['Authorization'] = token
          faraday.headers['Request-Id'] = SecureRandom.hex(3)
          faraday.adapter Faraday.default_adapter
        end
      end

      def token
        "Bearer #{Quickbooks::Payments::Authenticator.new.quickbooks_access_token.token}"
      end

      private

      def post(url:, params: {})
        connect(method: :post, url: url, params: params)
      end

      def put(url:, params: {})
        connect(method: :put, url: url, params: params)
      end

      def delete(url:, params: {})
        connect(method: :delete, url: url, params: params)
      end

      def get(url:)
        connect(method: :get, url: url)
      end

      def connect(method:, url:, params: {})
        response = params.present? ? @connection.send(method, url, params.to_json) : @connection.send(method, url)
        body =
          begin
            JSON.parse(response.body)
          rescue StandardError
            {}
          end

        response_handler(response, body)
      end

      def quickbooks_bad_request(body)
        errors = body.dig('errors')
        raise errors.map { |e| e['moreInfo'] }.join(', ').presence || errors.map { |e| e['message'] }.join(', ')
      end

      def quickbooks_timeout
        raise 'Net::ReadTimeout'
      end

      def unresolvable_by_repeat(response)
        raise Quickbooks::Payments::Error.new(
          error_data: { response: response },
          error_type: Quickbooks::Payments::Errors::UnResolvableByRepeat
        )
      end

      def resolvable_by_repeat(err)
        raise Quickbooks::Payments::Error.new(
          error_data: { error_code: err.class, error_text: err.message },
          error_type: Quickbooks::Payments::Errors::ResolvableByRepeat
        )
      end

      def response_handler(response, body)
        case response.status
        when 200..299 then body
        when 300..399 then {}
        when 400..499 then quickbooks_bad_request(body)
        when 500..599 then quickbooks_timeout
        else unresolvable_by_repeat(response)
        end
      rescue StandardError => e
        resolvable_by_repeat(e)
      end
    end
  end
end
