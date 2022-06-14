# frozen_string_literal: true

module Quickbooks
  class DeleteCardService < BaseService
    attr_reader :user, :external_card_id

    def initialize(user:, external_card_id:)
      @user = user
      @external_card_id = external_card_id
    end

    def call
      delete_request(url: "/v4/customers/#{user.qb_id}/cards/#{external_card_id}")
    end
  end
end
