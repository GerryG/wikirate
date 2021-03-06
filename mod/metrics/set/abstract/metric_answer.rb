card_accessor :checked_by
card_accessor :check_requested_by
card_accessor :source

# for hybrid metrics: If a calculated value is overridden by a researched value
#   then :overridden_value holds on to that value. It also serves as flag to mark
#   overridden answers
card_accessor :overridden_value, type: PhraseID

# virtual card's _values_ are held in the content of the _answer_ card
# (...not that I understand why - EM)
def value
  virtual? ? content : value_card&.value
end

# since real answers require real values, it is assumed that new answers
# (and only new answers) will have new values
def fetch_value_card
  fetch :value, new: new_value_card_args
end

def new_value_card_args
  { type_code: value_cardtype_code, supercard: self }
end

def value_card
  vc = fetch_value_card
  vc.content = content_from_value(value) if virtual?
  vc
end

# make sure pointer-style content works for multi-category
def content_from_value value
  Array.wrap(::Answer.value_from_lookup(value, value_type_code)).join "\n"
end

# MISCELLANEOUS METHODS

def scored_answer_card
  return self unless metric_type == :score

  metric_card&.basic_metric_card&.field(company)&.field(year)
end

# so that all fields show up in history
# (not needed when they can be identified via a more conventional form)
def history_card_ids
  field_card_ids << id
end

def field_card_ids
  [:value, :checked_by, :source, :check_requested_by].map do |field|
    fetch(field, skip_virtual: true, skip_modules: true)&.id
  end.compact
end

def calculating?
  calculated? && answer.calculating
end

def expire cache_type=nil
  super
  Card.expire [name, :value].to_name
end
