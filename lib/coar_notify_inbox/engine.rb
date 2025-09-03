module CoarNotifyInbox
  class Engine < ::Rails::Engine
    isolate_namespace CoarNotifyInbox
    config.generators.api_only = true
  end
end
