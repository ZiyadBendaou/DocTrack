# config/environments/development.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # --------------------------------------------------------------------------
  # ActionMailer configuration for development
  # --------------------------------------------------------------------------

  # Generate full URLs in emails
  config.action_mailer.default_url_options = {
    host: 'localhost',
    port: 3000
  }

  # Raise errors if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Actually send out emails in development
  config.action_mailer.perform_deliveries = true

  # Choose SMTP as the delivery method
  config.action_mailer.delivery_method = :smtp

  # SMTP settings for Zoho Mail
  config.action_mailer.smtp_settings = {
    address:              'smtp-relay.brevo.com',
    port:                 587,
    domain:               'doctrack.dev',
    user_name:            ENV['SMTP_USERNAME'], # e.g. contact@doctrack.dev
    password:             ENV['SMTP_PASSWORD'], # your Zoho (app‑specific) password
    authentication:       :plain,
    enable_starttls_auto: true
  }

  # Disable caching of mailer views
  config.action_mailer.perform_caching = false

  # --------------------------------------------------------------------------
  # Caching, logging, and other default Rails settings
  # --------------------------------------------------------------------------
  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Allow ngrok domains (if you use ngrok for tunneling)
  config.hosts << /.*\.ngrok\.io$/
  config.hosts << /.*\.ngrok-free\.app$/
end
