require 'rails_helper'

RSpec.describe 'Build API', :type => :request do
  describe 'request build version' do
    it 'should return support status that is not invalid' do
      build = create(:build)
      get "/builds/#{build.name}"
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq("{\"supportLevel\":\"#{build.support_level}\"}")
    end

    it 'should return invalid if build name is wrong' do
      build = create(:build)
      get "/builds/wrong_build_name"
      expect(response).to be_success
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq("{\"supportLevel\":\"invalid\"}")
    end
  end
end