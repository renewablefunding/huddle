module Huddle
  class User
    include RemoteResource

    class << self
      def current
        new(fetch_xml("entry"))
      end
    end
  end
end