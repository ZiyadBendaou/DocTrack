
redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/1'
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)

class Rack::Attack

  throttle('ocr/user/daily', limit: 10, period: 24.hours) do |req|
    if req.path == '/documents' && req.post? && req.params['extract'].present?
      req.env['warden']&.user&.id
    end
  end


  blocklist('block unauthenticated ocr access') do |req|
    req.path == '/documents' && req.post? && req.params['extract'].present? &&
      req.env['warden']&.user.nil?
  end


  def self.html_response(status, title, message)
    body = <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <title>#{status} - #{title}</title>
          <style>
            * {
              box-sizing: border-box;
            }
            body {
              font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
              background-color: #f8f9fa;
              color: #212529;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
            }
            .card {
              background: #fff;
              padding: 2.5rem;
              border-radius: 16px;
              box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
              text-align: center;
              max-width: 440px;
              width: 100%;
            }
            h1 {
              font-size: 1.75rem;
              color: #d90429;
              margin-bottom: 1rem;
            }
            p {
              font-size: 1rem;
              color: #555;
              margin-bottom: 2rem;
            }
            a.button {
              display: inline-block;
              padding: 0.75rem 1.5rem;
              font-size: 1rem;
              background-color: #0051ff;
              color: #fff;
              border-radius: 8px;
              text-decoration: none;
              font-weight: 600;
              transition: background-color 0.25s ease;
            }
            a.button:hover {
              background-color: #003bcc;
            }
          </style>
        </head>
        <body>
          <div class="card">
            <h1>#{title}</h1>
            <p>#{message}</p>
            <a href="/" class="button">Back to Home</a>
          </div>
        </body>
      </html>
    HTML
    [status, { 'Content-Type' => 'text/html' }, [body]]
  end


  self.throttled_responder = lambda do |request|
    html_response(
      429,
      "Too Many Requests",
      "You've reached your daily limit for OCR. Please try again tomorrow."
    )
  end


  self.blocklisted_responder = lambda do |request|
    html_response(
      403,
      "Access Denied",
      "You must be logged in to use OCR."
    )
  end
end
