require 'rails_helper'

RSpec.describe Bulletin, :type => :model do
  context '#before_save' do
    let(:published_at) { DateTime.now }
    let(:bulletin) do
      create(:bulletin, display_published_at: published_at.iso8601)
    end

    it 'populates #published_at with a DateTime equivalent' do
      expect(bulletin.published_at.to_i).to eq(published_at.to_i)
    end
  end

  context "validation" do
    it 'requires a valid date' do
      expect(build(:bulletin, display_published_at: '')).to_not be_valid
    end

    it 'requires a group' do
      expect(build(:bulletin, group: nil)).to_not be_valid
    end
  end
end