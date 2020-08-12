# frozen_string_literal: true

# Serializer used to render a DFC CatalogItem from an OFN Product
# into JSON-LD format based on DFC ontology
module DfcProvider
  class CatalogItemSerializer < ActiveModel::Serializer
    attribute :id, key: '@id'
    attribute :type, key: '@type'
    attribute :references, key: 'dfc:references'
    attribute :sku, key: 'dfc:sku'
    attribute :stock_limitation, key: 'dfc:stockLimitation'
    has_many :offered_through,
             serializer: DfcProvider::OfferSerializer,
             key: 'dfc:offeredThrough'

    def id
      "/catalog_items/#{object.id}"
    end

    def type
      'dfc:CatalogItem'
    end

    def references
      {
        '@type' => '@id',
        '@id' => "/supplied_products/#{object.product_id}"
      }
    end

    def sku
      object.sku
    end

    def stock_limitation; end

    def offered_through
      [object]
    end
  end
end
