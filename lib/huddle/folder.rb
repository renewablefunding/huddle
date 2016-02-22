module Huddle
  class Folder
    include RemoteResource

    find_at "/files/folders/:id"

    def name
      parsed_xml.get("displayName")
    end

    def owner
      one("actor[@rel='owner']", type: Huddle::User)
    end

    def folders
      many("folders/folder", type: Huddle::Folder, associations: { "workspace" => workspace })
    end

    def documents
      many(
        "documents/document",
        type: Huddle::Document,
        associations: { "workspace" => workspace, "folder" => self }
      )
    end

    def workspace
      one("workspace", type: Huddle::Workspace, fetch: true)
    end
  end
end