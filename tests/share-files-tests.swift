import Foundation

func rejects(_ operation: () throws -> Void) -> Bool {
    do { try operation(); return false } catch { return true }
}

@main struct ShareFilesTests {
    static func main() throws {
        let base = try configuredURL("https://files.example.test/inbox/")
        for text in ["report.pdf", "https://files.example.test/inbox/report.pdf", "https://files.example.test:443/inbox/report.pdf?k=1&dl"] {
            _ = try scopedURL(text, base: base)
        }
        for text in [
            "http://files.example.test/inbox/report.pdf",
            "https://other.example.test/inbox/report.pdf",
            "https://files.example.test:8443/inbox/report.pdf",
            "https://files.example.test/inbox-other/report.pdf",
            "https://files.example.test/elsewhere/report.pdf",
            "../report.pdf", "%2e%2e/report.pdf", "sub/%2e%2e/report.pdf",
            "sub%5creport.pdf", "report.pdf?password=secret", "report.pdf#fragment",
            "https://user:secret@files.example.test/inbox/report.pdf",
        ] {
            precondition(rejects { _ = try scopedURL(text, base: base) }, "Accepted out-of-scope URL: \(text)")
        }
        for text in [
            "", "http://files.example.test/inbox/", "/inbox/",
            "https://user:secret@files.example.test/inbox/",
            "https://files.example.test/inbox/?password=secret",
            "https://files.example.test/inbox/#fragment",
            "https://files.example.test/inbox", "https://files.example.test/a/../inbox/",
            "https://files.example.test/a/%2e%2e/inbox/",
            "https://files.example.test/a%5cb/", "https://files.example.test/a%00b/",
        ] {
            precondition(rejects { _ = try configuredURL(text) }, "Accepted invalid configuration: \(text)")
        }
        let customPort = try configuredURL("https://files.example.test:8443/My%20Files/")
        _ = try scopedURL("report.pdf", base: customPort)
        precondition(rejects { _ = try scopedURL("https://files.example.test/My%20Files/report.pdf", base: customPort) })
        let rootFolder = try configuredURL("https://files.example.test/")
        _ = try scopedURL("report.pdf", base: rootFolder)

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("config.json")
        precondition(rejects { _ = try loadBaseURL(from: file) })
        try Data(#"{"base_url":"https://files.example.test/inbox/"}"#.utf8).write(to: file)
        let loaded = try loadBaseURL(from: file)
        precondition(loaded == base)
        for text in ["{}", "not JSON", #"{"base_url":"http://files.example.test/inbox/"}"#] {
            try Data(text.utf8).write(to: file)
            precondition(rejects { _ = try loadBaseURL(from: file) })
        }
        print("Configuration loading and HTTPS origin/folder restrictions passed; no Keychain or network access.")
    }
}
