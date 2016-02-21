module Huddle
  class User
    include RemoteResource

    find_at "/users/:id"

    def name
      parsed_xml.at_xpath("profile/personal/displayname").text
    end

    def workspaces
      parsed_xml.xpath("membership/workspaces/workspace").map { |workspace_xml|
        Huddle::Workspace.new(workspace_xml)
      }
    end

    class << self
      def current
        find_by_path("/entry")
      end
    end
  end
end