require 'rails_helper'

RSpec.describe "WordParts", type: :request do
  describe "GET /phonics_levels/:phonics_level_id/word_parts" do
    let!(:phonics_level) { PhonicsLevel.create!(level_number: 1) }
    let!(:dog) { WordPart.create!(label: "dog", phonics_level: phonics_level, position: 2) }
    let!(:cat) { WordPart.create!(label: "cat", phonics_level: phonics_level, position: 1) }

    it "returns all word parts for the level" do
      get "/phonics_levels/#{phonics_level.id}/word_parts"

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
    end

    it "returns word parts ordered by position" do
      get "/phonics_levels/#{phonics_level.id}/word_parts"

      json_response = JSON.parse(response.body)
      expect(json_response.first["label"]).to eq("cat")
      expect(json_response.second["label"]).to eq("dog")
    end

    context "when phonics level does not exist" do
      it "returns a 404 status" do
        get "/phonics_levels/99999/word_parts"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a search term" do
      let!(:other_level) { PhonicsLevel.create!(level_number: 2) }
      let!(:cot) { WordPart.create!(label: "cot", phonics_level: other_level, position: 1) }

      it "filters by label" do
        get "/phonics_levels/#{phonics_level.id}/word_parts", params: { search: "ca" }

        expect(JSON.parse(response.body).map { |w| w["label"] }).to eq([ "cat" ])
      end

      it "treats SQL in the search term as a literal string" do
        get "/phonics_levels/#{phonics_level.id}/word_parts", params: { search: "zzz' OR label LIKE '" }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end

      it "handles a quote in the search term" do
        get "/phonics_levels/#{phonics_level.id}/word_parts", params: { search: "o'" }

        expect(response).to have_http_status(:ok)
      end

      it "stays within the requested level" do
        get "/phonics_levels/#{phonics_level.id}%20OR%201=1/word_parts", params: { search: "o" }

        expect(JSON.parse(response.body).map { |w| w["label"] }).to eq([ "dog" ])
      end

      it "matches % literally" do
        WordPart.create!(label: "50%", phonics_level: phonics_level, position: 3)

        get "/phonics_levels/#{phonics_level.id}/word_parts", params: { search: "%" }

        expect(JSON.parse(response.body).map { |w| w["label"] }).to eq([ "50%" ])
      end

      it "matches _ literally" do
        WordPart.create!(label: "a_b", phonics_level: phonics_level, position: 3)

        get "/phonics_levels/#{phonics_level.id}/word_parts", params: { search: "_" }

        expect(JSON.parse(response.body).map { |w| w["label"] }).to eq([ "a_b" ])
      end

      it "does not error on an array search param" do
        get "/phonics_levels/#{phonics_level.id}/word_parts?search[]=a"

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
