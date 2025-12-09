# COAR-Notify Inbox Rails Engine

A Rails engine providing a COAR Notify Inbox.

This is designed to function as a standalone COAR Notify inbox supporting [v1.0.1 of the COAR Notify specification](https://coar-notify.net/specification/1.0.1/), but also to be integrated into a [Samvera Hyrax](https://github.com/samvera/hyrax) (v5.2) repository. It is therefore implemented in Rails 7.2 which is a requirement of Hyrax 5.2.

There is a [related Hyrax 5.2 integration GitHub repository](https://github.com/antleaf/hyrax-coar-notify). 

---

# Using This Engine as a Gem (from GitHub)

Follow these steps in your **host Rails application**:

---

## 1. Add the engine to your Gemfile

```ruby
gem "coar_notify_inbox", git: "https://github.com/antleaf/coar-notify-inbox-rails-engine", branch: "feature/notification"
```
## 2. Install Gem
```bash
bundle install
```
## 3. Run migrations
```bash
rails db:create db:migrate
```
 ## 4. Mount the engine
 ```ruby
 # config/routes.rb
 Rails.application.routes.draw do
  mount CoarNotifyInbox::Engine => "/coar_notify_inbox"
end
```
Start the server 
```bash
rails server
```
**To verify the engine is mounted paste the URL `http://localhost:3000/coar_notify_inbox/senders` in the browser. You should see "Unauthorized" until you create users (correct behavior).**

---
# Initial Setup (Very Important)
Open a Rails console in the host app:
```ruby
rails console
```
Create an admin: (copy and paste this inside rails console)
```bash
admin = CoarNotifyInbox::User.create!(username: "admin", name: "Admin", role: :admin, active: true)
puts "Admin Token: #{admin.auth_token}"
```
copy the token since you will require this token to access API's using `Authorization: Bearer <TOKEN>`
---

# API Documentation
Full API documentation (with request + response examples) is available here: [docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)

# Postman Collection (Recommended for Testing)
A complete Postman test suite is provided.
Import these two files:
 - Instructions for use: [docs/POSTMAN_COLLECTION.md](docs/POSTMAN_COLLECTION.md)

## Contributing
PRs are welcome.
Please open issues for enhancements or questions.
