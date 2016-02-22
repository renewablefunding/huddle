module Huddle
  class User
    include RemoteResource

    find_at "/users/:id"

    def name
      parsed_xml.at_xpath("profile/personal/displayname").text
    end

    def workspaces
      @workspaces ||= parsed_xml.xpath("membership/workspaces/workspace").map { |workspace_xml|
        Huddle::Workspace.new(workspace_xml, session: @session)
      }
    end

    class << self
      def current(session: Huddle.default_session)
        find_by_path("/entry", session: session)
      end
    end
  end
end