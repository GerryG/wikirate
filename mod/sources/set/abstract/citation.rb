# add source card if needed
event :auto_add_source, :prepare_to_validate,
      on: :save, changed: :content, trigger: :required do
  auto_add_url_items
end

# make sure sources exists, are valid, and are properly annotated
event :validate_and_normalize_sources, :validate,
      on: :save, changed: :content do
  errors.add :content, "sources required" if item_names.blank? && required_field?
  annotate_sources
end

private

# sources not always required.
def required_field?
  left&.source_required?
end

# ANNOTATION

# when an answer cites a source, make sure
#   1. the source's +company has the answer's company
#   2. the source's +report_type has the answer's metric's report type
def annotate_sources
  item_names.each do |source_name|
    with_valid_source source_name do |source_card|
      tag_with_report_type source_card
      tag_with_company source_card
      tag_with_year source_card
    end
  end
end

def tag_with_report_type source_card
  return unless (report_types = left&.report_type&.item_names)&.present?
  add_trait_to_source source_card, :report_type, report_types
end

# note: company names overridden in answer and relationship_answer
def tag_with_company source_card
  add_trait_to_source source_card, :wikirate_company, company_names
end

def tag_with_year source_card
  add_trait_to_source source_card, :year, year
end

# TODO: move these to type/source!
def add_trait_to_source source_card, trait, values
  trait_card = source_card.fetch trait, new: {}
  Array.wrap(values).each { |val| trait_card.add_item val }
  add_subcard trait_card if trait_card.db_content_changed?
end

# VALIDATION

def with_valid_source source_name
  source_card = Card[source_name]
  if source_card&.type_id == SourceID
    yield source_card
  else
    invalid_source_item source_name
  end
end

def invalid_source_item source_name
  errors.add :item, invalid_source_item_error_message(source_name)
end

def invalid_source_item_error_message source_name
  if Self::Source.url? source_name
    "Adding urls as sources directly requires event configuration"
  else
    "No such source exists: #{source_name}"
  end
end

# AUTO ADD SOURCES

def auto_add_url_items
  item_names.each do |item|
    next unless Self::Source.url? item
    source_card = find_or_add_source_card item
    drop_item item
    add_item source_card.name
  end
end

def find_or_add_source_card url
  found = Self::Source.search_by_url url
  return found.first if found.present?

  Card.create type: SourceID, "+:wikirate_link" => url
end
