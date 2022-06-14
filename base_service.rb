# frozen_string_literal: true

module Quickbooks
  class BaseService < ApplicationService
    include HTTParty

    base_uri Rails.application.credentials.dig(Rails.env.to_sym, :quickbooks, :base_url)

    def headers
      {
        'Request-Id' => SecureRandom.hex(3),
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{quickbooks_access_token}"
      }
    end

    def quickbooks_access_token
      qb_credentials = QbCredential.first

      return qb_credentials.access_token if (Time.current - 50.minutes) < qb_credentials.updated_at

      token_set = generate_new_token(qb_credentials)
      update_qb_credentials(qb_credentials, token_set)

      token_set.token
    end

    def generate_new_token(qb_credentials)
      OAuth2::AccessToken.new(
        ::QB_OAUTH2_CONSUMER,
        qb_credentials.access_token,
        refresh_token: qb_credentials.refresh_token
      ).refresh!
    end

    def update_qb_credentials(qb_credentials, token_set)
      qb_credentials.update(access_token: token_set.token, refresh_token: token_set.refresh_token)
    end

    def post_request(url:, body:)
      quickbooks_rescue do
        self.class.post(url, body: body, headers: headers)
      end
    end

    def delete_request(url:)
      quickbooks_rescue do
        self.class.delete(url, headers: headers)
      end
    end

    def quickbooks_rescue
      response = yield
      return response if response.success?

      message =
        response.parsed_response['errors'][0]['moreInfo'] || response.parsed_response['errors'][0]['message']

      raise ExceptionHandler::QuickBooksError, message
    end
  end
end
