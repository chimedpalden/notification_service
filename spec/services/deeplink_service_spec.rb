# frozen_string_literal: true

require 'rails_helper'

describe DeeplinkService do
  let(:deeplink_service) { described_class.new(procedure_id, step_name) }
  let(:procedure_id) { 1 }
  let(:step_name) { 'presrciber_step' }

  describe "#get_deeplink" do
    before do
      allow_any_instance_of(described_class).to receive(:get_deeplink).and_return("/workflow/#{procedure_id}")
    end

    it "returns deeplink URL for the treatment id" do
      expect(deeplink_service.get_deeplink).to eq("/workflow/#{procedure_id}")
    end
  end

  describe '#fetch_deeplink_via_api' do
    subject { deeplink_service.send(:fetch_deeplink_via_api) }

    before do
      stub_request(:get, /deeplinks/).and_return(body: { 'url' => "workflow/#{procedure_id}" }.to_json, status: 200)
    end

    it 'returns workflow URL' do
      expect(subject).to eq("workflow/#{procedure_id}")
    end
  end
end
