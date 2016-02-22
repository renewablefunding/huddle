module Huddle
  class Document
    include RemoteResource

    find_at "/files/documents/:id"

    def title
      parsed_xml.get("title")
    end

    def description
      parsed_xml.get("description")
    end

    def owner
      one("actor[@rel='owner']", type: Huddle::User)
    end

    def folder
      fetch_from_link(
        "folder",
        link: "parent-folder",
        type: Huddle::Folder,
        associations: { "workspace" => workspace }
      )
    end

    def workspace
      one("workspace", type: Huddle::Workspace, fetch: true)
    end
  end
end