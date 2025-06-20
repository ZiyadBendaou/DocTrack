class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy, :confirm]
  require 'date'
  require 'google/cloud/vision/v1'

  def index
    @documents = Document.all
  end

  def show; end

  def confirm
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)
    @document.user = current_user

    if @document.save
      begin

        path = ActiveStorage::Blob.service.send(:path_for, @document.file.blob.key)

        vision = Google::Cloud::Vision::V1::ImageAnnotator::Client.new
        response = vision.text_detection(image: path)
        text = response.responses[0]&.text_annotations&.first&.description || ""

        # Extract date(s) and update document
        extracted_dates = extract_valid_dates(text)
        if extracted_dates.any?
          @document.update(expiration_date: extracted_dates.first)
        end

      rescue => e
        Rails.logger.error "OCR error: #{e.message}"
      end

      redirect_to confirm_document_path(@document), notice: "Document created. Please confirm the extracted expiration date."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @document.update(document_params)
      redirect_to @document, notice: "Document updated."
    else
      render :edit
    end
  end

  def destroy
    @document.destroy
    redirect_to documents_path, notice: "Document deleted."
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
      begin
        return Date.strptime(str, fmt)
      rescue ArgumentError
        next
      end
    end
    nil
  end

  def parse_month_year(str)
    parts = str.split('/')
    return nil unless parts.size == 2
    month = parts[0].to_i
    year = parts[1].to_i
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
