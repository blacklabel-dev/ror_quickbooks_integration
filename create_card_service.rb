# frozen_string_literal: true

module Quickbooks
  class CreateCardService < BaseService
    attr_reader :user, :body

    def initialize(user:, body:)
      @user = user
      @body = {
        number: body[:card_number].delete(' '),
        expMonth: body[:card_exp_month],
        expYear: body[:card_exp_year],
        cvc: body[:cvc]
      }.to_json
    end

    def call
      raise ExceptionHandler::ServiceError, 'QB Customer needs to exist.' unless @user.qb_id

      post_request(url: "/v4/customers/#{@user.qb_id}/cards", body: body)
    end
  end
end
