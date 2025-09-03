import Foundation

class ProfileService: ObservableObject {
    private let baseURL = "https://faas-ams3-2a2df116.doserverless.co/api/v1/namespaces/fn-d59df3b2-493f-4da1-a003-a35c0d6a276c/actions/test-profiles"
    private let authorization = "Basic NjcwNWU4ZjItNjI4OC00YmUyLWI4NWItMzU1NDhjODM3MGRhOkpyQ1hQWkNBcFBabUFwMkRod083a1MyTnVDdjR2MzhobzFkQmFBcFRablY0YWV1MFF6YloxUUxMVG82MG15QjQ="
    
    @Published var profiles: [Profile] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isLoadingNextPage = false
    @Published var hasMore = true
    
    private(set) var currentPage: Int = 0
    private(set) var currentLimit: Int = 20
    
    func resetAndLoadFirstPage(limit: Int = 20) async {
        await MainActor.run {
            self.profiles = []
            self.error = nil
            self.hasMore = true
            self.currentPage = 0
            self.currentLimit = limit
        }
        await fetchProfiles(page: 1, limit: limit, append: false)
    }
    
    func fetchNextPageIfPossible() async {
        if isLoading || isLoadingNextPage || !hasMore { return }
        await fetchProfiles(page: max(currentPage, 1) + 1, limit: currentLimit, append: true)
    }
    
    func fetchProfiles(page: Int = 1, limit: Int = 20, append: Bool) async {
        await MainActor.run {
            if append {
                isLoadingNextPage = true
            } else {
                isLoading = true
                error = nil
            }
        }
        
        guard let url = URL(string: "\(baseURL)?blocking=true&result=true") else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
                isLoadingNextPage = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["page": page, "limit": limit]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    error = "Invalid HTTP response"
                    isLoading = false
                    isLoadingNextPage = false
                }
                return
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                let raw = String(data: data, encoding: .utf8) ?? "<no body>"
                await MainActor.run {
                    error = "HTTP \(httpResponse.statusCode). Body: \(raw)"
                    isLoading = false
                    isLoadingNextPage = false
                }
                return
            }
            
            #if DEBUG
            if let rawString = String(data: data, encoding: .utf8) {
                print("[ProfileService] Raw JSON: \(rawString)")
            }
            #endif
            
            let decoded = try decodeProfiles(from: data)
            let candidates = decoded.filter { isUsableImageURL($0.imageURL) }
            let usable = await filterProfilesWithReachableImages(candidates)
            
            await MainActor.run {
                if append {
                    self.profiles.append(contentsOf: usable)
                } else {
                    self.profiles = usable
                }
                #if DEBUG
                let missing = decoded.filter { $0.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
                let unreachable = candidates.count - usable.count
                let basicInvalid = max(0, decoded.count - (candidates.count + missing))
                if missing > 0 { print("[ProfileService] Profiles missing imageURL: \(missing)") }
                if basicInvalid > 0 { print("[ProfileService] Profiles skipped due to invalid URLs: \(basicInvalid)") }
                if unreachable > 0 { print("[ProfileService] Profiles skipped due to unreachable images: \(unreachable)") }
                #endif
                self.currentPage = page
                self.currentLimit = limit
                self.hasMore = decoded.count >= limit
                self.isLoading = false
                self.isLoadingNextPage = false
                if decoded.isEmpty && !append {
                    self.error = "No profiles returned"
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                self.isLoadingNextPage = false
            }
        }
    }

    private func isUsableImageURL(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else { return false }
        if scheme != "https" { return false }
        guard url.host != nil else { return false }
        return true
    }
    
    private func filterProfilesWithReachableImages(_ profiles: [Profile]) async -> [Profile] {
        if profiles.isEmpty { return [] }
        var validated: [Profile] = []
        validated.reserveCapacity(profiles.count)
        await withTaskGroup(of: (Profile, Bool).self) { group in
            for profile in profiles {
                group.addTask { [weak self] in
                    let ok = await self?.isImageReachable(profile.imageURL) ?? false
                    return (profile, ok)
                }
            }
            for await (profile, ok) in group {
                if ok { validated.append(profile) }
            }
        }
        return validated
    }
    
    private func isImageReachable(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        var head = URLRequest(url: url)
        head.httpMethod = "HEAD"
        head.timeoutInterval = 5
        do {
            let (_, response) = try await URLSession.shared.data(for: head)
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                if let type = http.value(forHTTPHeaderField: "Content-Type")?.lowercased(), type.contains("image/") {
                    return true
                }
                return true
            }
        } catch {
            // HEAD might be unsupported; fall back to GET
        }
        var get = URLRequest(url: url)
        get.httpMethod = "GET"
        get.timeoutInterval = 7
        do {
            let (_, response) = try await URLSession.shared.data(for: get)
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                return true
            }
        } catch {
            return false
        }
        return false
    }
    
    private func decodeProfiles(from data: Data) throws -> [Profile] {
        let decoder = JSONDecoder()
        if let resp = try? decoder.decode(ProfileResponse.self, from: data) {
            return resp.profiles
        }
        if let arr = try? decoder.decode([Profile].self, from: data) {
            return arr
        }
        if let any = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let profiles = any["profiles"] as? [[String: Any]] { return profiles.compactMap(mapProfile(dict:)) }
            if let profiles = any["result"] as? [[String: Any]] { return profiles.compactMap(mapProfile(dict:)) }
            if let profiles = any["data"] as? [[String: Any]] { return profiles.compactMap(mapProfile(dict:)) }
            if let profiles = any["items"] as? [[String: Any]] { return profiles.compactMap(mapProfile(dict:)) }
        }
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return arr.compactMap(mapProfile(dict:))
        }
        return []
    }
    
    private func mapProfile(dict: [String: Any]) -> Profile? {
        let id: String = {
            if let s = dict["id"] as? String { return s }
            if let i = dict["id"] as? Int { return String(i) }
            if let u = dict["uuid"] as? String { return u }
            return UUID().uuidString
        }()
        
        let name: String = {
            if let n = dict["name"] as? String { return n }
            let first = (dict["firstName"] as? String) ?? (dict["first_name"] as? String) ?? ""
            let last = (dict["lastName"] as? String) ?? (dict["last_name"] as? String) ?? ""
            let full = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
            return full.isEmpty ? "Unknown" : full
        }()
        
        let age: Int = {
            if let a = dict["age"] as? Int { return a }
            if let s = dict["age"] as? String, let a = Int(s) { return a }
            return 18
        }()
        
        let imageURL: String = {
            if let s = dict["image_url"] as? String { return s }
            if let s = dict["image"] as? String { return s }
            if let s = dict["photo"] as? String { return s }
            if let s = dict["avatar"] as? String { return s }
            return ""
        }()
        
        let isOnline: Bool = {
            if let b = dict["is_online"] as? Bool { return b }
            if let b = dict["online"] as? Bool { return b }
            if let i = dict["online"] as? Int { return i != 0 }
            if let status = dict["online_status"] as? String { return status.lowercased() == "online" }
            return false
        }()
        
        let country: String = (dict["country"] as? String)
            ?? (dict["nation"] as? String)
            ?? ""
        
        let lastSeen: Date? = {
            if let timestamp = dict["last_seen"] as? TimeInterval { return Date(timeIntervalSince1970: timestamp) }
            if let timestamp = dict["last_seen"] as? String { return ISO8601DateFormatter().date(from: timestamp) }
            return nil
        }()
        
        let onlineStatus: String? = dict["online_status"] as? String
        
        return Profile(id: id, name: name, age: age, imageURL: imageURL, isOnline: isOnline, country: country, lastSeen: lastSeen, onlineStatus: onlineStatus)
    }
}
