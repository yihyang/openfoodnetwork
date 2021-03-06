# frozen_string_literal: true

require 'spec_helper'
require 'stripe/credit_card_cloner'

module Stripe
  describe CreditCardCloner do
    describe "#clone" do
      include StripeStubs

      let(:cloner) { Stripe::CreditCardCloner.new }

      let(:customer_id) { "cus_A123" }
      let(:payment_method_id) { "pm_1234" }
      let(:new_customer_id) { "cus_A456" }
      let(:new_payment_method_id) { "pm_456" }
      let(:stripe_account_id) { "acct_456" }
      let(:payment_method_response_mock) { { status: 200, body: payment_method_response_body } }

      let(:credit_card) { create(:credit_card, user: create(:user)) }

      let(:payment_method_response_body) {
        JSON.generate(id: new_payment_method_id)
      }

      before do
        allow(Stripe).to receive(:api_key) { "sk_test_12345" }

        stub_customers_post_request email: credit_card.user.email,
                                   response: { customer_id: new_customer_id },
                                   stripe_account_header: true
        stub_request(:post,
                     "https://api.stripe.com/v1/payment_methods/#{new_payment_method_id}/attach")
          .with(body: { customer: new_customer_id },
                headers: { 'Stripe-Account' => stripe_account_id })
          .to_return(payment_method_response_mock)

        credit_card.update_attribute :gateway_payment_profile_id, payment_method_id
      end

      context "when called with a card without a customer (one time usage card)" do
        before do
          stub_request(:post, "https://api.stripe.com/v1/payment_methods")
            .with(body: { payment_method: payment_method_id },
                  headers: { 'Stripe-Account' => stripe_account_id })
            .to_return(payment_method_response_mock)
        end

        it "clones the payment method only" do
          customer_id, payment_method_id = cloner.clone(credit_card, stripe_account_id)

          expect(payment_method_id).to eq new_payment_method_id
          expect(customer_id).to eq nil
        end
      end

      context "when called with a valid customer and payment_method" do
        before do
          stub_request(:post, "https://api.stripe.com/v1/payment_methods")
            .with(body: { customer: customer_id, payment_method: payment_method_id },
                  headers: { 'Stripe-Account' => stripe_account_id })
            .to_return(payment_method_response_mock)

          credit_card.update_attribute :gateway_customer_profile_id, customer_id
        end

        it "clones both the payment method and the customer" do
          customer_id, payment_method_id = cloner.clone(credit_card, stripe_account_id)

          expect(payment_method_id).to eq new_payment_method_id
          expect(customer_id).to eq new_customer_id
        end
      end
    end
  end
end
