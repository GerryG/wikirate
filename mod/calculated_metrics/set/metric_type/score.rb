include Set::Abstract::Calculation

# <OVERRIDES>
def score?
  true
end

def ten_scale?
  true
end

def needs_name?
  false
end

def formula_editor
  categorical? ? :categorical_editor : super
end

def formula_core
  categorical? ? :categorical_core : super
end
# </OVERRIDES>

def scorer
  name.tag
end

def scorer_card
  right
end

def basic_metric
  name.trunk
end

def basic_metric_card
  left
end

def categorical?
  basic_metric_card.categorical?
end

def normalize_value value
  return value if value.is_a? String
  return "0" if value.negative?
  return "10" if value > 10
  value.to_s
end

def value_type
  "Number"
end

def value_options
  basic_metric_card.value_options
end

event :validate_score_name, :validate, changed: :name, on: :save do
  unless basic_metric_card&.type_id == MetricID
    errors.add :name, "#{basic_metric} is not a metric"
  end
  unless Card[scorer]&.type_id.in? [UserID, ResearchGroupID]
    errors.add :name, "Invalid Scorer: #{scorer}; must be a User or Research Group"
  end
end

event :set_scored_metric_name, :initialize, on: :create do
  return if name.parts.size >= 3
  metric = remove_subfield(:metric)&.first_name
  self.name = "#{metric}+#{Auth.current.name}"
end

event :default_formula, :prepare_to_store, on: :create, when: :formula_unspecified? do
  add_subfield :formula, content: "{{#{basic_metric}}}", type_id: PlainTextID
end

def formula_unspecified?
  !subfield(:formula)&.content&.present?
end
