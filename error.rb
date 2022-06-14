# frozen_string_literal: true

module Quickbooks
  module Payments
    class Error < StandardError
      attr_accessor :error_data, :error_type

      def initialize(error_type: nil, error_data: {})
        @error_data = error_data
        @error_type = error_type
        super
      end
    end
  end
end
