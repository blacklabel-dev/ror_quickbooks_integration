# frozen_string_literal: true

module Quickbooks
  module Payments
    module Presenters
      class CreateCard
        def present(body: {})
          return body if body.blank?

          {
            "number": body[:card_number].delete(' '),
            "expMonth": body[:card_exp_month],
            "expYear": body[:card_exp_year],
            "cvc": body[:cvc],
            "name_on_card": body[:name_on_card]
          }
        end
      end
    end
  end
end
