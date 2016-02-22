module Huddle
  class Workspace
    include RemoteResource

    find_at "/workspaces/:id"

    def type
      parsed_xml.get("type")
    end

    def title
      parsed_xml.get("title")
    end

    def document_library_folder
      fetch_from_link(
        "folder",
        link: "documentLibrary",
        type: Huddle::Folder,
        associations: { "workspace" => self }
      )
    end
  end
end