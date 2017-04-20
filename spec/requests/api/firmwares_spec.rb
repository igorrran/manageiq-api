RSpec.describe "firmwares API" do
  describe "display firmware details" do
    context "with a valid role" do
      it "shows its properties" do
        fw = FactoryGirl.create(:firmware, :id => 1, :name => "UEFI",
                                :version => "D7E152CUS-2.11", :resource_id => 1)

        api_basic_authorize action_identifier(:firmwares, :read, :resource_actions, :get)

        run_get(firmwares_url(fw.id))

        expect_single_resource_query("id"          => 1,
                                     "name"        => "UEFI",
                                     "version"     => "D7E152CUS-2.11",
                                     "resource_id" => 1)
      end
    end

    context "with an invalid role" do
      it "fails to show its properties" do
        fw = FactoryGirl.create(:firmware, :id => 1)

        api_basic_authorize

        run_get(firmwares_url(fw.id))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
