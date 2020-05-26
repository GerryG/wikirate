class Answer
  # Methods to handle answers that exist only in the the answer table
  # and don't have a card. Used for calculated answers.
  module CardlessAnswers
    def self.included host_class
      host_class.extend ClassMethods
    end

    def find_answer_card
      # for unknown reasons there are cases where `Card[record_name, year.to_s]` exists
      # for virtual answers. Fetching `Card[record_name, year.to_s, :value]` first,
      # ensures that we don't get a card when we don't want one.
      Card[record_name, year.to_s, :value]&.left
    end

    def virtual_answer_card name=nil, val=nil
      name ||= virtual_answer_name
      val ||= value

      # TODO: obviate the type setting here
      # (this would be more efficient, because it gets renewed this way, but
      # for that to work we need to be able to set default type_ids via code)
      Card.fetch(name, new: { type_id: Card::MetricAnswerID }).tap do |card|
        card.define_singleton_method(:virtual?) { true }
        card.define_singleton_method(:value) { val }
        # card.define_singleton_method(:updated_at) { updated_at }
        card.define_singleton_method(:value_card) do
          ::Answer.virtual_value name, val, value_type_code, value_cardtype_code
        end
      end
    end

    def virtual_answer_name
      (record_name ? [record_name] : [metric_id, company_id]) << year.to_s
    end

    # true if there is no card for this answer
    def virtual?
      card&.virtual?
    end

    def calculated_answer metric_card, company, year, value
      @card = virtual_answer_card metric_card.answer_name_for(company, year), value
      refresh
      @card.expire
      update_cached_counts
      self
    end

    def update_cached_counts
      (simple_cache_count_cards + topic_cache_count_cards).each(&:update_cached_count)
    end

    def simple_cache_count_cards
      [[metric_id, :metric_answer],
       [metric_id, :wikirate_company],
       [company_id, :metric],
       [company_id, :metric_answer],
       [company_id, :wikirate_topic]].map do |mark|
        Card.fetch(mark)
      end
    end

    def topic_cache_count_cards
      Card::Set::TypePlusRight::WikirateTopic::WikirateCompany
        .company_cache_cards_for_topics Card[metric_id]&.wikirate_topic_card&.item_names
    end

    def update_value value
      update! value_attributes(value)
    end

    def value_attributes value
      {
        value: value,
        numeric_value: to_numeric_value(value),
        updated_at: Time.now,
        editor_id: Card::Auth.current_id,
        calculating: false
      }
    end

    def restore_overridden_value
      calculated_answer metric_card, company, year, overridden_value
    end

    # class methods for {Answer} to support creating and updating calculated answers
    module ClassMethods
      def virtual_value name, val, value_type_code, value_cardtype_code
        Card.new name: [name, :value],
                 content: ::Answer.value_from_lookup(val, value_type_code),
                 type_code: value_cardtype_code
      end

      def create_calculated_answer metric_card, company, year, value
        Answer.new.calculated_answer metric_card, company, year, value
      end
    end
  end
end
