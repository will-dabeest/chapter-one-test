class WordPartsController < ApplicationController
  def index
    @phonic_level = PhonicsLevel.find(params[:phonics_level_id])
    @word_parts = @phonic_level.word_parts

    search = params[:search].to_s
    if search.present?
      @word_parts = @word_parts.where("label LIKE ? ESCAPE '\\'", "%#{WordPart.sanitize_sql_like(search)}%")
    end

    render json: @word_parts
  end
end
