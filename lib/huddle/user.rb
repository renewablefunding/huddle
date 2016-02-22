module Huddle
  class User
    include RemoteResource

    find_at "/users/:id"

    def name
      parsed_xml.get("name") ||
        parsed_xml.at_xpath("profile/personal/displayname").text
    end

    def workspaces
      many("membership/workspaces/workspace", type: Huddle::Workspace)
    end

    class << self
      def current(session: Huddle.default_session)
        find_by_path("/entry", session: session)
      end
    end
  end
end