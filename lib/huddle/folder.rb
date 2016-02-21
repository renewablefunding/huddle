module Huddle
  class Folder
    include RemoteResource

    find_at "/files/folders/:id"
  end
end