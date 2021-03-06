RSpec.describe Card::Set::Type::WikirateCompany do
  it "shows the link for view \"missing\"" do
    html = render_card :unknown, type_id: Card::WikirateCompanyID,
                                 name: "non-existing-card"
    expect(html).to eq(render_card(:link, type_id: Card::WikirateCompanyID,
                                          name: "non-existing-card"))
  end

  describe "creating company with post request", type: :controller do
    routes { Decko::Engine.routes }
    before { @controller = CardController.new }

    let(:token) do
      Card::Auth.as_bot do
        Card["Joe Admin", :account, :api_key].update! content: "abcd"
        "abcd"
      end
    end

    it "creates company" do
      post :create, params: { card: { name: "new company",
                                      type: "Company",
                                      subcards: { "+:open_corporates" => "C0806592",
                                                  "+:headquarters" => "us_ca" } },
                              success: { format: :json },
                              api_key: token }
      expect_card("new company")
        .to exist
        .and have_a_field(:open_corporates).with_content("C0806592")
        .and have_a_field(:headquarters).with_content("[[California (United States)]]")
    end
  end

  describe "renaming company" do
    let(:company_card) { Card["Death Star"] }

    def rename_company!
      company_card.update! name: "Life Star"
    end

    it "refreshes all answers" do
      rename_company!
      expect(Answer.where(company_id: "Death Star".card_id).count).to eq(0)
    end
  end

  describe "deleting company" do
    let(:company_card) { Card["Death Star"] }

    def delete_company!
      company_card.delete!
    end

    it "deletes all answers", as_bot: true do
      company_id = company_card.id
      delete_company!
      expect(Answer.where(company_id: company_id).count).to eq(0)
    end
  end
end
