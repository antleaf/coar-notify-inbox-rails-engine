Rails.application.routes.draw do
  mount TmpPlugin::Engine => "/tmp_plugin"
end
