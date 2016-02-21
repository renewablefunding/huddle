module Huddle
  class User
    include RemoteResource

    self.resource_path = "/users/:id"

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