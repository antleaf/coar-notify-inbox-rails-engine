# Using this engine 

You can embed this engine within you rails application, or run the engine as a stand alone COAR Notify inbox. The setup within the rails application is the same in both cases.

There are instruction below on how to use this engine as a gem within your rails application.

---

## Using this engine as a gem

Follow these steps in your **host Rails application**

---

### 1. Add the engine to your Gemfile (from GitHub)

```ruby
gem "coar_notify_inbox", git: "https://github.com/antleaf/coar-notify-inbox-rails-engine", branch: "feature/notification"
```

### 2. Install gem

```bash
bundle install
```

### 3. Run migrations

```bash
rails db:create db:migrate
```

 ### 4. Mount the engine

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

**NOTE:** To verify the engine is mounted paste the URL `http://localhost:3000/coar_notify_inbox/senders` in the browser. You should see "Unauthorized" until you create users (correct behavior)

---

## Testing the engine with the test rails application 

If you would like to try the engine before embedding it in your rails application, a test rails application is available as a part of this repository in the directory [.notify_inbox_test](../.notify_inbox_test)

The [.notify_inbox_test/README.md](../.notify_inbox_test/README.md) has instructions on how to run the application

---

## Initial setup

Once you have the engine up and running, it is very important to create an admin user. This will generate an auth_token for the admin user, which is needed to using the engine through its API.

Open a Rails console in the host app:

```ruby
rails console
```

Create an admin: (copy and paste this inside rails console)

```bash
admin = CoarNotifyInbox::User.create!(username: "admin", name: "Admin", role: :admin, active: true)
puts "Admin Token: #{admin.auth_token}"
```

**IMPORTANT** Save this token securely as you'll need it to authenticate API requests using `Authorization: Bearer <TOKEN>`.

---


## API documentation

Full API documentation (with request + response examples) is available at [docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)

### Postman collection

A complete Postman test suite is provided. The docs on using the postman collection is at [docs/POSTMAN_COLLECTION.md](docs/POSTMAN_COLLECTION.md)
