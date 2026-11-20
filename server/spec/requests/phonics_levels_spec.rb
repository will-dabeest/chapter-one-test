require 'rails_helper'

RSpec.describe "PhonicsLevels", type: :request do
  describe "GET /phonics_levels" do
    let!(:level_one) { PhonicsLevel.create!(level_number: 1) }
    let!(:level_three) { PhonicsLevel.create!(level_number: 3) }
    let!(:level_two) { PhonicsLevel.create!(level_number: 2) }

    before do
      WordPart.create!(label: "a", phonics_level: level_one, position: 0)
      WordPart.create!(label: "b", phonics_level: level_one, position: 1)
      WordPart.create!(label: "c", phonics_level: level_three, position: 0)
    end

    def level_numbers
      JSON.parse(response.body).map { |l| l["level_number"] }
    end

    it "includes word_part_count for each level" do
      get "/phonics_levels"

      counts = JSON.parse(response.body).to_h { |l| [ l["level_number"], l["word_part_count"] ] }
      expect(counts).to eq(1 => 2, 2 => 0, 3 => 1)
    end

    it "counts word parts with one query, not one per level" do
      word_part_queries = []
      callback = lambda do |*, payload|
        word_part_queries << payload[:sql] if payload[:name] != "SCHEMA" && payload[:sql].include?("word_parts")
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/phonics_levels"
      end

      expect(word_part_queries.size).to eq(1)
    end

    it "orders by level_number by default" do
      get "/phonics_levels"

      expect(level_numbers).to eq([ 1, 2, 3 ])
    end

    it "filters by min_level" do
      get "/phonics_levels", params: { min_level: 2 }

      expect(level_numbers).to eq([ 2, 3 ])
    end

    it "falls back to level_number for an unknown order_by" do
      get "/phonics_levels", params: { order_by: "bogus" }

      expect(response).to have_http_status(:ok)
      expect(level_numbers).to eq([ 1, 2, 3 ])
    end

    it "ignores SQL injected into min_level" do
      get "/phonics_levels", params: { min_level: "3 OR 1=1" }

      expect(level_numbers).to eq([ 3 ])
    end

    it "orders by id when asked" do
      get "/phonics_levels", params: { order_by: "id" }

      expect(level_numbers).to eq([ 1, 3, 2 ])
    end

    it "does not error on an array min_level param" do
      get "/phonics_levels?min_level[]=3"

      expect(response).to have_http_status(:ok)
    end
  end
end
