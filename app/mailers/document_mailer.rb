class DocumentMailer < ApplicationMailer
  default from: 'contact@doctrack.dev'

  def reminder(document)
    @document = document
    @user     = document.user

    mail(
      to:      @user.email,
      subject: "Reminder: your “#{@document.document_type}” expires on #{@document.expiration_date.strftime('%d/%m/%Y')}"
    )
  end
end
