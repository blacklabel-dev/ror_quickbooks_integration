# frozen_string_literal: true

module Quickbooks
  class CustomerService
    def create(user:)
      raise ExceptionHandler::ServiceError, 'Could not create customer without username.' unless user.username

      customer = Quickbooks::Model::Customer.new(given_name: user.username,
                                                 email_address: user.email)
      customer.billing_address = billing_address(user)

      begin
        quickbooks_customer = quickbooks_customer_service.create(customer)
        user if user.update_attribute('qb_id', quickbooks_customer.id)
      rescue StandardError => e
        e.message
      end
    end

    def fetch(user:)
      return false unless user&.qb_id

      begin
        quickbooks_customer_service.fetch_by_id(user.qb_id)
      rescue StandardError => e
        e.message
      end
    end

    def update(user:)
      raise ExceptionHandler::ServiceError, 'Could not update customer without id.' unless user.qb_id

      customer = quickbooks_customer_service.fetch_by_id(user.qb_id)
      customer.billing_address = billing_address(user)

      begin
        quickbooks_customer_service.update(customer)
      rescue StandardError => e
        e.message
      end
    end

    private

    def quickbooks_customer_service
      @quickbooks_customer_service ||=
        Quickbooks::Service::Customer.new(
          access_token: Quickbooks::Payments::Authenticator.new.quickbooks_access_token,
          company_id: QUICKBOOKS_REALM_ID
        )
    end

    def billing_address(user)
      billing_info = user.billing_info

      city = billing_info&.city&.presence || user.city
      state = billing_info&.state&.presence || user.state

      billing_city_and_state = [city, state].compact.join(', ')

      Quickbooks::Model::PhysicalAddress.new(
        line1: billing_info&.address&.presence || user.address_line1,
        city: billing_city_and_state,
        postal_code: billing_info&.zip_code&.presence || user.zip_code
      )
    end
  end
end
