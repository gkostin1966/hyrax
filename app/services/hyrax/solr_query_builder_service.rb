module Hyrax
  # Methods in this class are from/based on ActiveFedora::SolrQueryBuilder
  class SolrQueryBuilderService
    class << self
      # Construct a solr query for a list of ids
      # This is used to get a solr response based on the list of ids in an object's RELS-EXT relationhsips
      # If the id_array is empty, defaults to a query of "id:NEVER_USE_THIS_ID", which will return an empty solr response
      # @param [Array] id_array the ids that you want included in the query
      def construct_query_for_ids(id_array)
        ids = id_array.reject(&:blank?)
        return "id:NEVER_USE_THIS_ID" if ids.empty?
        "{!terms f=#{Hyrax.config.id_field}}#{ids.join(',')}"
      end

      # Construct a solr query from a list of pairs (e.g. [field name, values])
      # @param [Array<Array>] field_pairs a list of pairs of property name and values
      # @param [String] join_with ('AND') the value we're joining the clauses with
      # @param [String] type ('field') The type of query to run. Either 'raw' or 'field'
      # @return [String] a solr query
      # @example
      #   construct_query([['library_id_ssim', '123'], ['owner_ssim', 'Fred']])
      #   # => "_query_:\"{!field f=library_id_ssim}123\" AND _query_:\"{!field f=owner_ssim}Fred\""
      def construct_query(field_pairs, join_with = default_join_with, type = 'field'.freeze)
        clauses = pairs_to_clauses(field_pairs, type)
        return "" if clauses.count.zero?
        return clauses.first if clauses.count == 1
        "(#{clauses.join(join_with)})"
      end

      def default_join_with
        ' AND '
      end

      private

        # @param [Array<Array>] pairs a list of (key, value) pairs. The value itself may
        # @param [String] type  The type of query to run. Either 'raw' or 'field'
        # @return [Array] a list of solr clauses
        def pairs_to_clauses(pairs, type)
          pairs.flat_map do |field, value|
            condition_to_clauses(field, value, type)
          end
        end

        # @param [String] field
        # @param [String, Array<String>] values
        # @param [String] type The type of query to run. Either 'raw' or 'field'
        # @return [Array<String>]
        def condition_to_clauses(field, values, type)
          values = Array(values)
          values << nil if values.empty?
          values.map do |value|
            if value.present?
              query_clause(type, field, value)
            else
              # Check that the field is not present. In SQL: "WHERE field IS NULL"
              "-#{field}:[* TO *]"
            end
          end
        end

        # Create a raw query clause suitable for sending to solr as an fq element
        # @param [String] type The type of query to run. Either 'raw' or 'field'
        # @param [String] key
        # @param [String] value
        def query_clause(type, key, value)
          "_query_:\"{!#{type} f=#{key}}#{value.gsub('"', '\"')}\""
        end
    end
  end
end
