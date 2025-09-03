# COAR-Notify Inbox Rails Engine

A Rails engine providing a COAR Notify Inbox.

This is designed to function as a standalone COAR Notify inbox supporting [v1.0.1 of the COAR Notify specification](https://coar-notify.net/specification/1.0.1/), but also to be integrated into a [Samvera Hyrax](https://github.com/samvera/hyrax) (v5.2) repository. It is therefore implemented in Rails 7.2 which is a requirement of Hyrax 5.2.

There is a [related Hyrax 5.2 integration GitHub repository](https://github.com/antleaf/hyrax-coar-notify). 

## Usage
To use this engine in your Rails application:

1. Add this line to your application's Gemfile (replace the URL with your repository if using Git):
   ```ruby
   gem 'coar-notify-inbox-rails-engine', git: 'https://github.com/your-org/coar-notify-inbox-rails-engine.git'
   ```

2. Run `bundle install`:
   ```bash
   bundle install
   ```

3. Mount the engine in your application's `config/routes.rb`:
   ```ruby
   mount CoarNotifyInbox::Engine => "/coar_notify_inbox"
   ```

4. Restart your Rails server.

The engine's routes and features will now be available under `/coar_notify_inbox` in your application.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "coar-notify-inbox-rails-engine"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install coar-notify-inbox-rails-engine
```

## Contributing
Contribution directions go here.
