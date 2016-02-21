module Huddle
  class Workspace
    include RemoteResource

    self.resource_path = "/workspaces/:id"
  end
end