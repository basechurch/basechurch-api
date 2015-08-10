# Sample variables:
#
# field: "banner"
# factory_name: :post
# class_name: "Basechurch::Post"
# update_attributes: { editor: create(:user) }

shared_examples_for "an attachment" do
  shared_examples_for "an optional url" do
    it "requires a valid url" do
      expect(build(factory_name, key => "hello_COD")).to_not be_valid
      expect(build(factory_name, key => "http://something.com")).to be_valid
    end
  end

  context "with a url" do
    let(:key) { "#{field}_url" }
    it_behaves_like "an optional url"
  end

  context "with an attachment" do
    let(:model) { create(factory_name) }
    let!(:attachment) do
      create(:attachment,
             element_id: model.id,
             element_type: class_name,
             element_key: field)
    end

    it "has an attachment" do
      expect(model.send(field)).to eq attachment
    end
  end

  context "#after_save" do
    let(:url) { "http://test.com/example.png" }
    let(:model) do
      create(factory_name, update_attributes.merge("#{field}_url" => url))
    end

    it "saves an attachment from the url provided" do
      expect(model.send(field).url).to eq url
    end

    context "when updating the url" do
      it "updates the attachement" do
        attachment_id = model.send(field).id
        model.send("#{field}_url=", "http://test.com/new.png")
        model.send(:save)

        expect(model.send(field).id).to eq attachment_id
        expect(model.send(field).url).to eq "http://test.com/new.png"
      end
    end
  end
end