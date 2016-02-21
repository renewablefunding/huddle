module Huddle
  class Folder
    include RemoteResource

    self.resource_path = "/files/folders/:id"
  end
end