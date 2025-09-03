require_relative "lib/coar_notify_inbox/version"

Gem::Specification.new do |spec|
  spec.name        = "coar-notify-inbox-rails-engine"
  spec.version     = CoarNotifyInbox::VERSION
  spec.authors     = [""]
  spec.email       = ["gyan@cottagelabs.com"]
  spec.homepage    = "https://github.com/antleaf/coar-notify-inbox-rails-engine"
  spec.summary     = "TODO: Summary of CoarNotifyInbox."
  spec.description = "TODO: Description of CoarNotifyInbox."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/antleaf/coar-notify-inbox-rails-engine"
  spec.metadata["changelog_uri"] = "https://github.com/antleaf/coar-notify-inbox-rails-engine/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0", "< 9.0"
end
