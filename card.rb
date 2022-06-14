# frozen_string_literal: true

module Quickbooks
  module Payments
    class Card < Quickbooks::Payments::Transciever
      attr_accessor :user, :body

      def initialize(body: {}, user:)
        @user = user

        @body = Quickbooks::Payments::Presenters::CreateCard.new.present(body: body)
        @base_url = Rails.application.credentials.dig(Rails.env.to_sym, :quickbooks, :base_url)
        super()
      end

      def create
        raise ExceptionHandler::ServiceError, 'QB Id needs to exist for cards operations.' unless user.qb_id

        begin
          post(url: "v4/customers/#{user.qb_id}/cards", params: body)
        rescue Quickbooks::Payments::Error => e
          raise ExceptionHandler::ServiceError, e.error_data&.dig(:error_text)
        end
      end

      def delete_card(external_card_id)
        raise ExceptionHandler::ServiceError, 'QB Id needs to exist for cards operations.' unless user.qb_id

        begin
          delete(url: "v4/customers/#{user.qb_id}/cards/#{external_card_id}")
        rescue Quickbooks::Payments::Error => e
          raise ExceptionHandler::ServiceError, e.error_data&.dig(:error_text)
        end
      end
    end
  end
end
