
return unless Rails.env.production? || Rails.env.development?

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

scheduler.cron '0 0 * * *' do
  Rails.logger.info "[Scheduler] Enqueue SendReminderEmailsJob"
  SendReminderEmailsJob.perform_later
end
