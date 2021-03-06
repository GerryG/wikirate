class Card
  class AnswerQuery
    # filter field handling
    module Filtering
      CARD_ID_MAP = { research_policy: :policy_id, metric_type: :metric_type_id }.freeze

      SIMPLE_FILTERS = ::Set.new(%i[company_id metric_id latest numeric_value]).freeze
      CARD_ID_FILTERS = ::Set.new(CARD_ID_MAP.keys).freeze

      protected

      def process_filters
        return if @empty_result
        @filter_args.each { |k, v| process_filter_option k, v if v.present? }
        @restrict_to_ids.each { |k, v| filter k, v }
      end

      # TODO: optimize with hash lookups for methods
      def process_filter_option key, value
        %i[exact_match card_id].each do |ftype|
          if send("#{ftype}_filters").include? key
            return send("filter_#{ftype}", key, value)
          end
        end
        try "#{key}_query", value
      end

      def filter_exact_match key, value
        return unless value.present?
        filter key, value
      end

      def filter_card_id key, value
        return unless (card_id = to_card_id value)

        filter CARD_ID_MAP[key], card_id
      end

      def to_card_id value
        if value.is_a?(Array)
          value.map { |v| Card.fetch_id(v) }
        else
          Card.fetch_id(value)
        end
      end

      def restrict_to_ids col, ids
        ids = Array(ids)
        @empty_result ||= ids.empty?
        restrict_answer_ids col, ids
      end

      def restrict_answer_ids col, ids
        existing = @restrict_to_ids[col]
        @restrict_to_ids[col] = existing ? (existing & ids) : ids
      end

      def restrict_by_wql col, wql
        wql.reverse_merge! return: :id, limit: 0
        restrict_to_ids col, Card.search(wql)
      end

      def exact_match_filters
        SIMPLE_FILTERS
      end

      def name_filters
        name_FILTERS
      end

      def card_id_filters
        CARD_ID_FILTERS
      end

      def filter key, value, operator=nil
        condition = "answers.#{key} #{op_and_val operator, value}"
        add_condition condition, value
      end

      def op_and_val op, val
        "#{db_operator op, val} #{db_value val}"
      end

      def add_condition condition, value
        @conditions << condition
        @values << value
      end

      def db_operator operator, value
        operator || (value.is_a?(Array) ? "IN" : "=")
      end

      def db_value value
        value.is_a?(Array) ? "(?)" : "?"
      end
    end
  end
end
