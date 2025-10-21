require_relative "lib/coar_notify_inbox/version"

Gem::Specification.new do |spec|
  spec.name        = "coar-notify-inbox-rails-engine"
  spec.version     = CoarNotifyInbox::VERSION
  spec.authors     = [""]
  spec.email       = ["gyan@cottagelabs.com"]
  spec.homepage    = "https://github.com/antleaf/coar-notify-inbox-rails-engine"
  spec.summary     = "Summary of CoarNotifyInbox."
  spec.description = "Description of CoarNotifyInbox."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/antleaf/coar-notify-inbox-rails-engine"
  spec.metadata["changelog_uri"] = "https://github.com/antleaf/coar-notify-inbox-rails-engine/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0", "< 9.0"
  spec.add_dependency "cancancan", "~> 3.5"
end
