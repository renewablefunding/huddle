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
      Huddle::Folder.find_by_path(links["documentLibrary"])
    end
  end
end