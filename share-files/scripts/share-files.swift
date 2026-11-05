import Foundation
import Security
import CryptoKit

let service = "copyparty-agents"
let account = "share-files"

struct Failure: Error { let message: String }
func fail(_ message: String) -> Failure { Failure(message: message) }
struct Configuration: Decodable {
    let baseURL: String
    enum CodingKeys: String, CodingKey { case baseURL = "base_url" }
}
func configuredURL(_ text: String) throws -> URL {
    guard let parts = URLComponents(string: text),
          parts.scheme == "https", let host = parts.host, !host.isEmpty,
          parts.user == nil, parts.password == nil,
          parts.query == nil, parts.fragment == nil,
          parts.port == nil || (1...65535).contains(parts.port!),
          let path = parts.percentEncodedPath.removingPercentEncoding,
          path.hasPrefix("/"), path.hasSuffix("/"), !path.contains("\\"),
          !path.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
          !path.split(separator: "/").contains(where: { $0 == ".." || $0 == "." }),
          let url = parts.url else {
        throw fail("base_url must be an absolute HTTPS folder URL ending in /, without credentials, query parameters, fragments, or traversal segments.")
    }
    return url
}
func loadBaseURL(from file: URL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/share-files/config.json")) throws -> URL {
    let config: Configuration
    do {
        config = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: file))
    } catch {
        throw fail("Create ~/.config/share-files/config.json with a base_url string containing the HTTPS destination folder URL. Keep credentials in Keychain.")
    }
    return try configuredURL(config.baseURL)
}
func emit(_ value: [String: Any]) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    print(String(decoding: data, as: UTF8.self))
}
func keychainQuery() -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service, kSecAttrAccount as String: account]
}
func credential() throws -> String {
    var query = keychainQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data,
          let value = String(data: data, encoding: .utf8) else {
        throw fail("Keychain read failed (status \(status)); check sandbox access, item existence, lock state, or approval.")
    }
    return value
}
func storeCredential(_ path: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: path))
    // Accept a conventional final newline in a supplied secret file.
    if data.last == 10 { data.removeLast(); if data.last == 13 { data.removeLast() } }
    guard !data.isEmpty, !data.contains(10), !data.contains(13),
          String(data: data, encoding: .utf8) != nil else {
        throw fail("The credential must be nonempty UTF-8 text on one line.")
    }
    var query = keychainQuery()
    query[kSecValueData as String] = data
    query[kSecAttrLabel as String] = "Copyparty Agents"
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw fail("Keychain store failed (status \(status)); an existing item is never replaced automatically.")
    }
    guard try credential().utf8.elementsEqual(data) else { throw fail("Keychain readback failed.") }
    try emit(["stored": true, "service": service, "account": account])
}

func scopedURL(_ text: String, base: URL) throws -> URL {
    guard let url = URL(string: text, relativeTo: base)?.absoluteURL,
          let parts = URLComponents(url: url, resolvingAgainstBaseURL: true),
          parts.scheme == "https", parts.host?.lowercased() == base.host?.lowercased(),
          (parts.port ?? 443) == (base.port ?? 443),
          parts.user == nil, parts.password == nil, parts.fragment == nil,
          let path = parts.percentEncodedPath.removingPercentEncoding,
          let basePath = URLComponents(url: base, resolvingAgainstBaseURL: true)?
            .percentEncodedPath.removingPercentEncoding,
          path.hasPrefix(basePath), !path.contains("\\"),
          !path.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
          !path.split(separator: "/").contains(where: { $0 == ".." || $0 == "." }),
          (parts.queryItems ?? []).allSatisfy({ ["k", "dl"].contains($0.name) }) else {
        throw fail("Only file URLs inside the configured HTTPS folder, with optional k or dl parameters, are accepted.")
    }
    return url
}
func withQuery(_ url: URL, name: String) -> URL {
    var parts = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    var items = parts.queryItems ?? []
    if !items.contains(where: { $0.name == name }) { items.append(URLQueryItem(name: name, value: nil)) }
    parts.queryItems = items
    return parts.url!
}
final class NoRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}
func request(_ url: URL, password: String, method: String = "GET") -> URLRequest {
    var req = URLRequest(url: url)
    req.httpMethod = method
    req.setValue(password, forHTTPHeaderField: "PW")
    return req
}
func validResponse(_ response: URLResponse) throws -> HTTPURLResponse {
    guard let http = response as? HTTPURLResponse else { throw fail("Missing HTTP response.") }
    guard (200..<300).contains(http.statusCode) else { throw fail("HTTP \(http.statusCode); redirects are not followed.") }
    return http
}
func digest(_ url: URL) throws -> String {
    let file = try FileHandle(forReadingFrom: url)
    defer { try? file.close() }
    var hash = SHA256()
    while let chunk = try file.read(upToCount: 1024 * 1024), !chunk.isEmpty { hash.update(data: chunk) }
    return hash.finalize().map { String(format: "%02x", $0) }.joined()
}
func download(_ url: URL, password: String, session: URLSession) async throws -> URL {
    let (file, response) = try await session.download(for: request(withQuery(url, name: "dl"), password: password))
    do {
        let http = try validResponse(response)
        if let disposition = http.value(forHTTPHeaderField: "Content-Disposition"),
           disposition.lowercased().contains("attachment") { /* Copyparty file download. */ }
        else if http.mimeType?.lowercased().contains("text/html") == true {
            throw fail("HTML without an attachment header may be a login page; download was not accepted.")
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        let size = try FileManager.default.attributesOfItem(atPath: file.path)[.size] as? NSNumber
        if response.expectedContentLength >= 0, size?.int64Value != response.expectedContentLength {
            throw fail("Download length does not match the HTTP response.")
        }
        return file
    } catch {
        try? FileManager.default.removeItem(at: file)
        throw error
    }
}

#if !SHARE_FILES_TESTING
@main struct ShareFiles {
    static func main() async {
        do { try await run(Array(CommandLine.arguments.dropFirst())) }
        catch let error as Failure { fputs("share-files: \(error.message)\n", stderr); exit(1) }
        catch let error as URLError {
            fputs("share-files: network error \(error.code.rawValue); an upload may have completed. Check the destination before retrying.\n", stderr); exit(1)
        }
        catch { fputs("share-files: operation failed (\(type(of: error))); no credential or response body is logged.\n", stderr); exit(1) }
    }
    static func run(_ args: [String]) async throws {
        guard let command = args.first else { throw fail("Use --help for usage.") }
        if command == "--help" {
            print("""
            share-files store-file SECRET_PATH   Store a new Keychain item, without printing its value
            share-files config-check             Validate local configuration without credentials or network access
            share-files check                    Check authenticated folder access
            share-files list                     List the configured folder
            share-files upload LOCAL_FILE        Upload with a unique name and verify by SHA-256 readback
            share-files download FILE_URL DEST   Download to a new local path; never replace an existing file
            """)
            return
        }
        if command == "store-file", args.count == 2 { try storeCredential(args[1]); return }
        let base = try loadBaseURL()
        if command == "config-check", args.count == 1 {
            try emit(["configured": true]); return
        }
        var target: URL?
        var local: URL?
        if command == "upload", args.count == 2 {
            local = URL(fileURLWithPath: args[1]).standardizedFileURL
            guard try local!.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
                throw fail("Upload requires an existing regular file.")
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.timeZone = TimeZone(secondsFromGMT: 0)
            let name = formatter.string(from: Date()) + "-" + UUID().uuidString.prefix(8).lowercased() + "-" + local!.lastPathComponent
            target = try scopedURL(base.appendingPathComponent(name).absoluteString, base: base)
        } else if command == "download", args.count == 3 {
            target = try scopedURL(args[1], base: base)
            local = URL(fileURLWithPath: args[2]).standardizedFileURL
            guard !FileManager.default.fileExists(atPath: local!.path) else { throw fail("Destination already exists.") }
        } else if !(["check", "list"].contains(command) && args.count == 1) {
            throw fail("Invalid arguments; use --help.")
        }
        let password = try credential()
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil; config.urlCache = nil
        config.timeoutIntervalForRequest = 60; config.timeoutIntervalForResource = 3600
        let session = URLSession(configuration: config, delegate: NoRedirects(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        if command == "check" || command == "list" {
            let (data, response) = try await session.data(for: request(withQuery(base, name: "ls"), password: password))
            _ = try validResponse(response)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let files = json["files"] as? [[String: Any]], let dirs = json["dirs"] as? [[String: Any]] else {
                throw fail("Expected a Copyparty JSON folder listing; response was not accepted.")
            }
            var result: [String: Any] = ["authenticated": true, "files": files.count, "directories": dirs.count]
            if command == "list" {
                result["entries"] = (dirs + files).map { entry in
                    ["href": entry["href"] ?? "", "bytes": entry["sz"] ?? 0]
                }
            }
            try emit(result)
        } else if command == "upload" {
            let expected = try digest(local!)
            var req = request(withQuery(target!, name: "j"), password: password, method: "PUT")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            let (_, response) = try await session.upload(for: req, fromFile: local!)
            _ = try validResponse(response)
            // Verify the explicitly named PUT destination independently of
            // response-link formatting or backend/proxy origins.
            let stored = target!
            let copy = try await download(stored, password: password, session: session)
            defer { try? FileManager.default.removeItem(at: copy) }
            guard try digest(copy) == expected else { throw fail("Upload readback SHA-256 mismatch.") }
            try emit(["verified": true, "url": stored.absoluteString, "sha256": expected])
        } else {
            let copy = try await download(target!, password: password, session: session)
            defer { try? FileManager.default.removeItem(at: copy) }
            let sha256 = try digest(copy)
            try FileManager.default.moveItem(at: copy, to: local!)
            try emit(["downloaded": true, "path": local!.path, "sha256": sha256,
                      "verification": "HTTP completion and byte length when reported; SHA-256 recorded locally, not compared with a server checksum"])
        }
    }
}
#endif
