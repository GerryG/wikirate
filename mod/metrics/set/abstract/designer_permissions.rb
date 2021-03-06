# eg include_set Abstract::DesignerPermissions
#
# Cards with this set must respond to #metric_card.
#
# If the metric is "designer assessed", then cards with this set can only be edited by
# the designer (or members of the WikiRate team)

def as_designer?
  Card::Auth.as_id == metric_card.metric_designer_card.id
end

def check_designer_permissions action
  return true if !metric_card&.designer_assessed? || as_moderator? || as_designer?
  deny_because "Only the metric designer can #{action} this on designer-assessed metrics"
end

def ok_to_create
  super && check_designer_permissions(:create)
end

def ok_to_update
  super && check_designer_permissions(:update)
end

# delete logic is different, because most users don't have permission by default
def ok_to_delete
  return true if metric_card&.try(:designer_assessed?) && as_designer?
  super
end
