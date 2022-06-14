# frozen_string_literal: true

module Quickbooks
  module Payments
    class Authenticator
      def quickbooks_access_token
        qb_credentials = QbCredential.first

        return access_token(qb_credentials) if (Time.current - 50.minutes) < qb_credentials.updated_at

        generate_new_token(qb_credentials)
      end

      def generate_new_token(qb_credentials)
        refreshed_token = access_token(qb_credentials).refresh!
        update_qb_credentials(qb_credentials, refreshed_token)
        refreshed_token
      end

      def access_token(qb_credentials)
        OAuth2::AccessToken.new(
          ::QB_OAUTH2_CONSUMER,
          qb_credentials.access_token,
          refresh_token: qb_credentials.refresh_token
        )
      end

      private

      def update_qb_credentials(qb_credentials, token_set)
        qb_credentials.update(access_token: token_set.token, refresh_token: token_set.refresh_token)
      end
    end
  end
end
