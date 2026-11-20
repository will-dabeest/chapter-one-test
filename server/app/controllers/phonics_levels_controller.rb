class PhonicsLevelsController < ApplicationController
  ORDERABLE_COLUMNS = %w[ level_number id ].freeze

  def index
    min_level = (params[:min_level] || 1).to_s.to_i
    order_by = ORDERABLE_COLUMNS.include?(params[:order_by]) ? params[:order_by] : "level_number"
    @phonic_levels = PhonicsLevel.where("level_number >= ?", min_level).order(order_by)
    word_part_counts = WordPart.group(:phonics_level_id).count

    levels_with_counts = @phonic_levels.map do |level|
      level.as_json.merge(word_part_count: word_part_counts.fetch(level.id, 0))
    end

    render json: levels_with_counts
  end
end
