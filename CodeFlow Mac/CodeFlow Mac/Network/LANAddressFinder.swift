//
//  LANAddressFinder.swift
//  CodeFlow Mac
//

import Foundation

public enum LANAddressFinder {
    /// Discovers the active LAN IPv4 address (e.g. 192.168.x.x, 10.x.x.x).
    /// Prioritizes primary network interfaces (en0, en1) over others.
    public static func getPrimaryIPv4Address() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }

        var candidates: [(name: String, ip: String)] = []

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            guard addrFamily == UInt8(AF_INET) else { continue }

            let flags = Int32(interface.ifa_flags)
            // Skip loopback and down/inactive interfaces
            if (flags & IFF_LOOPBACK) != 0 { continue }
            if (flags & IFF_UP) == 0 { continue }
            if (flags & IFF_RUNNING) == 0 { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            ) == 0 {
                let ip = String(cString: hostname)
                let name = String(cString: interface.ifa_name)
                if !ip.isEmpty && ip != "127.0.0.1" && !ip.starts(with: "169.254.") {
                    candidates.append((name: name, ip: ip))
                }
            }
        }

        // Prioritize en0 (Wi-Fi or main Ethernet on macOS)
        if let en0 = candidates.first(where: { $0.name == "en0" }) {
            return en0.ip
        }
        // Then any en interface (en1, en2, etc.)
        if let anyEn = candidates.first(where: { $0.name.hasPrefix("en") }) {
            return anyEn.ip
        }

        return candidates.first?.ip
    }
}
