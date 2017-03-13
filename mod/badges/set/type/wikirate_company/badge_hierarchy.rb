#! no set module

class BadgeHierarchy
  extend Abstract::BadgeHierarchy

  add_badge_set :create,
                company_register: 1,
                the_company_store: 5,
                inc_slinger: 25,
                &create_type_count(WikirateCompanyID)

  add_badge_set :logo,
                logo_brick: 1,
                how_lo_can_you_go: 10,
                logo_and_behold: 100,
                &type_plus_right_edited_count(WikirateCompanyID, LogoID)
end