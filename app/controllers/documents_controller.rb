class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]
  require 'date'
  require 'google/cloud/vision/v1'

  def index
    @documents = Document.all
  end

  def show; end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)
    @document.user = current_user

    if params[:extract].present? && params[:document][:file].present?
      file = params[:document][:file]
      file_path = Rails.root.join("tmp", file.original_filename)
      File.open(file_path, "wb") { |f| f.write(file.read) }

      vision = Google::Cloud::Vision::V1::ImageAnnotator::Client.new
      response = vision.text_detection(image: file_path.to_s)
      extracted_text = response.responses[0]&.text_annotations&.first&.description || ""
      File.delete(file_path) if File.exist?(file_path)

      @document.expiration_date = extract_valid_dates(extracted_text).first
      @extracted = true
      @extracted_text = extracted_text
      flash.now[:notice] = "We found a possible expiration date. Please confirm or edit before saving."
      render :new and return
    end

    if @document.save
      redirect_to @document, notice: "Document successfully created."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @document.update(document_params)
      redirect_to @document, notice: "Document successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @document.destroy
    redirect_to documents_path, notice: "Document successfully deleted."
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:document_type, :expiration_date, :file)
  end

  def extract_valid_dates(text)
    today = Date.today
    regex = /\b((?:0?[1-9]|[12][0-9]|3[01])[\/\-.](?:0?[1-9]|1[0-2])[\/\-.](?:\d{2}|\d{4})|(?:\d{4})[\/\-.](?:0?[1-9]|1[0-2])[\/\-.](?:0?[1-9]|[12][0-9]|3[01])|(?:0?[1-9]|1[0-2])[\/\-](?:\d{2}|\d{4})|(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,4})\b/i
    dates = text.scan(regex).flatten.compact

    dates.map do |str|
      str = str.tr('.-', '/')
      parse_date_with_formats(str) || parse_month_year(str) || parse_month_name_year(str)
    end.compact.select { |date| date >= today }.uniq.sort
  end

  def parse_date_with_formats(str)
    ['%d/%m/%Y', '%d/%m/%y', '%Y/%m/%d'].each do |fmt|
      Date.strptime(str, fmt) rescue next
    end
    nil
  end

  def parse_month_year(str)
    parts = str.split('/')
    return nil unless parts.size == 2
    month, year = parts[0].to_i, parts[1].to_i
    year += 2000 if year < 100
    Date.new(year, month, -1) rescue nil
  end

  def parse_month_name_year(str)
    ['%b %y', '%b %Y', '%B %y', '%B %Y'].each do |fmt|
      begin
        date = Date.strptime(str.upcase, fmt)
        date = Date.new(date.year + 2000, date.month, 1) if date.year < 100
        return date
      rescue ArgumentError
        next
      end
    end
    nil
  end
end
