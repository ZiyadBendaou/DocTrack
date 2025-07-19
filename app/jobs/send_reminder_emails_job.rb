class SendReminderEmailsJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current


    Reminder.where(sent: false)
            .where("send_at <= ?", now)
            .includes(document: :user)
            .find_each do |reminder|

      DocumentMailer.reminder(reminder.document).deliver_later


      reminder.update!(sent: true)
    end
  end
end
