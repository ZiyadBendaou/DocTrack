class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]
  before_action :authorize_document, only: [:edit, :update, :destroy]

  require 'google/cloud/vision/v1'
  require 'securerandom'
  require 'tempfile'

  def index
    @documents = current_user.documents
  end

  def show; end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)
    @document.user = current_user

    # Se è stato richiesto l'OCR
    if extracting_date_from_image?
      if validate_uploaded_file(params[:document][:file])
        extract_expiration_date_with_ocr
      else
        flash.now[:alert] = "Only image files up to 5MB are allowed."
      end
      render :new and return
    end

    if @document.save
      generate_reminder_for(@document)
      redirect_to @document, notice: "Document successfully created."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @document.update(document_params)
      @document.reminders.destroy_all
      generate_reminder_for(@document)
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

  def authorize_document
    redirect_to documents_path, alert: "Not authorized" unless @document.user == current_user
  end

  def document_params
    base = params.require(:document).permit(:document_type, :expiration_date, :file, :reminder_days)
    base[:document_type] = params[:custom_document_type] if params[:custom_document_type].present?
    base
  end

  def extracting_date_from_image?
    params[:extract].present? && params.dig(:document, :file).present?
  end

  def validate_uploaded_file(file)
    file.content_type.start_with?('image/') && file.size <= 5.megabytes
  end

  def extract_expiration_date_with_ocr
    uploaded_file = params[:document][:file]
    @extracted = false

    tempfile = Tempfile.new([SecureRandom.uuid, File.extname(uploaded_file.original_filename)])
    tempfile.binmode
    tempfile.write(uploaded_file.read)
    tempfile.rewind

    begin
      vision = Google::Cloud::Vision::V1::ImageAnnotator::Client.new
      response = vision.text_detection(image: tempfile.path)

      extracted_text = response.responses[0]&.text_annotations&.first&.description || ""
      @document.expiration_date = extract_possible_dates(extracted_text).first

      @extracted = true
      @extracted_text = extracted_text
      flash.now[:notice] = "We found a possible expiration date. Please confirm or edit before saving."

    rescue => e
      flash.now[:alert] = "Error during OCR: #{e.message}"
    ensure
      tempfile.close!
    end
  end

  def generate_reminder_for(document)
    return unless document.reminder_days.present? && document.expiration_date.present?

    days_before = document.reminder_days.to_i
    send_at = document.expiration_date - days_before.days

    document.reminders.create(send_at: send_at, sent: false) if send_at >= Date.today
  end

  def extract_possible_dates(text)
    today = Date.today
    regex = %r{
      \b(
        (?:0?[1-9]|[12][0-9]|3[01])[\/\-.](?:0?[1-9]|1[0-2])[\/\-.](?:\d{2}|\d{4}) |
        (?:\d{4})[\/\-.](?:0?[1-9]|1[0-2])[\/\-.](?:0?[1-9]|[12][0-9]|3[01]) |
        (?:0?[1-9]|1[0-2])[\/\-](?:\d{2}|\d{4}) |
        (?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,4}
      )\b
    }ix

    text.scan(regex).flatten.compact.map do |str|
      clean = str.tr('.-', '/')
      parse_date_formats(clean) || parse_month_year(clean) || parse_month_name_year(clean)
    end.compact.select { |date| date >= today }.uniq.sort
  end

  def parse_date_formats(str)
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
    month, year = parts[0].to_i, parts[1].to_i
    year += 2000 if year < 100
    Date.new(year, month, -1) rescue nil
  end

  def parse_month_name_year(str)
    ['%b %y', '%b %Y', '%B %y', '%B %Y'].each do |fmt|
      begin
        date = Date.strptime(str.capitalize, fmt)
        date = Date.new(date.year + 2000, date.month, 1) if date.year < 100
        return date
      rescue ArgumentError
        next
      end
    end
    nil
  end
end
