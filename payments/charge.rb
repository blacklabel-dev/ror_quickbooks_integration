# frozen_string_literal: true

module Quickbooks
  module Payments
    class Charge < Quickbooks::Payments::Transciever
      def initialize
        @base_url = Rails.application.credentials.dig(Rails.env.to_sym, :quickbooks, :base_url)
        super
      end

      def create(body:)
        post(url: 'v4/payments/charges', params: body)
      rescue Quickbooks::Payments::Error => e
        raise ExceptionHandler::ServiceError, e.error_data&.dig(:error_text)
      end
    end
  end
end
