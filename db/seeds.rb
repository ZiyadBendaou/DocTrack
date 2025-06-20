# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Create a test user
user = User.find_or_create_by!(email: "test@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end


# Create a few sample documents (files will be dummy placeholders)
3.times do |i|
  doc = Document.new(
    document_type: "Sample Type #{i + 1}",
    expiration_date: Date.today + (30 * (i + 1)),
    user: user
  )

  # Attach a dummy file (replace with real ones if needed)
  doc.file.attach(
    io: File.open(Rails.root.join("app/assets/images/rails.png")), # use any existing file in your project
    filename: "dummy#{i + 1}.png",
    content_type: "image/png"
  )

  doc.save!
end

puts "Seeded 1 user and 3 documents."
