# frozen_string_literal: true

module Quickbooks
  module Payments
    class Invoice
      def create(user:, payment:, controller:)
        raise ExceptionHandler::ServiceError, 'There is no customer present.' unless user.qb_id
        raise ExceptionHandler::ServiceError, 'There are no line items.' if payment.line_items.blank?
        created_invoice = create_invoice_with_line_items(user, payment, controller)

        invoice_service.fetch_by_id(created_invoice.id)
      end

      def create_invoice_with_line_items(user, payment, controller)
        invoice = quickbooks_invoice_init(user, payment)
        invoice.line_items = payment.line_items.collect { |p_line_item| invoice_line_item(p_line_item, controller) }.flatten!

        invoice_service.create(invoice)
      end

      def fetch_by_external_id(external_invoice_id:)
        invoice_service.fetch_by_id(external_invoice_id)
      rescue Quickbooks::IntuitRequestException
        raise ExceptionHandler::ServiceError, 'Could not process your request for now.'
      end

      def email_invoice(payment:, mail_to_client:)
        SubscriptionMailer.new_sale_notification(payment).deliver_later
        return unless mail_to_client

        invoice = fetch_by_external_id(external_invoice_id: payment.external_invoice_id)
        invoice_service.send(invoice, CGI.escape(payment.user.email))
      end

      def download_invoice_pdf(invoice_id:)
        invoice = fetch_by_external_id(external_invoice_id: invoice_id)
        invoice_service.pdf(invoice)
      end

      private

      def invoice_service
        @invoice_service ||=
          Quickbooks::Service::Invoice.new(
            company_id: QUICKBOOKS_REALM_ID,
            access_token: Quickbooks::Payments::Authenticator.new.generate_new_token(QbCredential.first)
          )
      end

      def invoice_line_item(payment_line_item, controller)
        invoice_line_items = []
        total_amount = LineItemService.new.quantity_wise_price(true, controller: controller, line_item: payment_line_item)

        title = line_item_title(payment_line_item)
        invoice_line_items <<
          invoice_single_line_item(title, total_amount, payment_line_item.quantity)

        invoice_line_items
      end

      def invoice_single_line_item(title, total_amount, quantity)
        line_item = Quickbooks::Model::InvoiceLineItem.new
        line_item.amount = total_amount
        line_item.description = title
        line_item.sales_item! do |detail|
          detail.unit_price = total_amount / quantity # Unit Price
          detail.quantity = quantity # Quantity Details
        end
        line_item
      end

      def quickbooks_invoice_init(user, payment)
        Quickbooks::Model::Invoice.new(
          customer_id: user.qb_id, txn_date: payment.created_at, due_date: Date.current
        )
      end

      def line_item_title(line_item, title = '')
        title += LineItemService.new.line_item_discount_text(line_item)
        return title if line_item.coupon_discount.zero?

        coupon = line_item.coupon_code
        title += if coupon.percentage?
                   "(Coupon Discount #{coupon.discount_value}%)"
                 else
                   "(Coupon Discount #{coupon.discount_value} USD)"
                 end
        title
      end
    end
  end
end
