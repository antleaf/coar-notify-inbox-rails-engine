module CoarNotifyInbox
  class Engine < ::Rails::Engine
    isolate_namespace CoarNotifyInbox
    config.generators.api_only = true

    initializer :append_migrations do |app|
      if !app.root.to_s.match(root.to_s) && app.root.join('db/migrate').children.none? { |path| path.fnmatch?("*.coar_notify_inbox.rb") }
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
