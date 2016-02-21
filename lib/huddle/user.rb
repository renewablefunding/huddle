module Huddle
  class User
    include RemoteResource

    self.resource_path = "/users/:id"

    class << self
      def current
        find_by_path("/entry")
      end
    end
  end
end