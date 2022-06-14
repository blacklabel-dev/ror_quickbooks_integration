# frozen_string_literal: true

module Quickbooks
  module Payments
    module Presenters
      class CreateCharge
        def present(attrs:)
          {
            "amount": attrs[:amount]&.to_f&.round(2),
            "cardOnFile": attrs[:external_card_id]
          }.merge!(default_params)
        end

        def default_params
          {
            "context": {
              "mobile": 'false',
              "isEcommerce": 'true'
            },
            'currency': 'USD'
          }
        end
      end
    end
  end
end
