require 'rails_helper'

describe Api::V1::BulletinsController, type: :controller do
  let(:sunday_service) do
    create(:group)
  end

  let(:user) { create(:user) }

  let(:all_attributes) do
    {
      data: {
        type: "bulletins",
        attributes: {
          :"published-at" => DateTime.now.to_time.iso8601,
          name: Forgery(:lorem_ipsum).title,
          description: Forgery(:lorem_ipsum).words(10),
          :"service-order" => Forgery(:lorem_ipsum).words(10),
        },
        relationships: {
          group: {
            data: { type: "groups", id: sunday_service.id.to_s }
          }
        }
      }
    }
  end

  let(:full_bulletin) do
    b = all_attributes[:data][:attributes]
    create(:bulletin,
           published_at: DateTime.iso8601(b[:"published-at"]),
           name: b[:name],
           description: b[:description],
           service_order: b[:"service-order"],
           group: sunday_service)
  end

  let(:valid_attributes) do
    {
      data: {
        type: "bulletins",
        attributes: {
          :"published-at" => DateTime.now.to_time.iso8601,
        },
        relationships: {
          group: {
            data: { type: "groups", id: sunday_service.id.to_s }
          }
        }
      }
    }
  end

  shared_examples_for 'an action to create a bulletin' do
    let(:perform_action) { post :create, post_params }

    it 'creates a new bulletin' do
      expect { perform_action }.to change { Bulletin.count }.by(1)
    end

    context 'when successful' do
      before { perform_action }
      it_behaves_like 'a response containing a bulletin'
    end
  end

  shared_examples_for 'a response containing a bulletin' do
    it 'returns a bulletin' do
      data = JSON.parse(response.body)["data"]

      expect(data["id"]).to be_present
      expect(data["type"]).to eq "bulletins"
      expect(data["links"]["self"]).
        to start_with "http://test.host/api/v1/bulletins/"

      attributes = data["attributes"]
      expect(attributes["audioUrl"]).to eq bulletin.audio_url
      expect(attributes["bannerUrl"]).to eq bulletin.banner_url
      expect(attributes["description"]).to eq bulletin.description
      expect(attributes["name"]).to eq bulletin.name
      expect(attributes["published-at"]).
        to eq bulletin.published_at.to_time.localtime("+00:00").iso8601
      expect(attributes["sermonNotes"]).to eq bulletin.sermon_notes
      expect(attributes["service-order"]).to eq bulletin.service_order

      group_data = data["relationships"]["group"]["data"]
      expect(group_data["type"]).to eq "groups"
      expect(group_data["id"]).to eq bulletin.group.id.to_s

      announcements_data = data["relationships"]["announcements"]
      expect(announcements_data).not_to be_empty
    end
  end

  describe 'GET /sunday' do
    let!(:bulletin) do
      create(:bulletin, group: sunday_service, published_at: 20.seconds.ago)
    end

    let!(:old_bulletin) do
      create(:bulletin, group: sunday_service, published_at: 10.days.ago)
    end

    let!(:future_bulletin) do
      create(:bulletin, group: sunday_service, published_at: 10.days.from_now)
    end

    before { get :sunday }

    it_behaves_like 'a response containing a bulletin'
  end

  describe 'GET /bulletins/:id' do
    let(:bulletin) do
      create(:bulletin_with_announcements,
             published_at: DateTime.iso8601('2011-12-03T04:05:06+04:00'))
    end

    before { get :show, id: bulletin.id }

    it_behaves_like 'a response containing a bulletin'
  end

  describe "POST /bulletins" do
    let(:perform_action) { post :create, valid_attributes }

    context 'with an authenticated user' do
      before do
        request.headers['Content-Type'] = 'application/vnd.api+json'
        request.headers['X-User-Email'] = user.email
        request.headers['X-User-Token'] = user.session_api_key.access_token
      end

      context 'with minimum params required' do
        let(:post_params) { valid_attributes }
        let(:bulletin) do
          iso_date = valid_attributes[:data][:attributes][:"published-at"]
          create(:bulletin,
                 published_at: DateTime.iso8601(iso_date),
                 group: sunday_service)
        end

        it_behaves_like 'an action to create a bulletin'
      end

      context 'with all params provided' do
        let(:post_params) { all_attributes }
        let(:bulletin) { full_bulletin }
        it_behaves_like 'an action to create a bulletin'
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) { valid_attributes }

        context "where published_at is not iso8601 compliant" do
          before do
            attributes = invalid_attributes[:data][:attributes]
            attributes[:"published-at"] = "sdafasdfdsa"
            perform_action
          end

          subject { response }

          its(:status) { should == 422 }
        end
      end
    end

    it_behaves_like 'an authenticated action'
  end

  describe "s3 signing" do
    let(:directory) { "bulletins" }
    it_behaves_like "a request that returns a signature to upload to s3"
  end
end