module Huddle
  class Workspace
    include RemoteResource

    self.resource_path = "/workspaces/:id"

    def type
      parsed_xml.get("type")
    end

    def title
      parsed_xml.get("title")
    end

    def document_library_folder
      fetch_from_link("documentLibrary", type: Huddle::Folder)
    end
  end
end