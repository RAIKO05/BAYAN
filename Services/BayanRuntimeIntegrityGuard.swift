import Foundation
import UIKit
import Darwin
import MachO

// MARK: - Bayan Subsystem Diagnostics & Runtime Integrity Guard
/// Obfuscated Anti-Reverse Engineering & Jailbreak Detection Engine.
/// Uses intentionally non-obvious symbol names and indirect probes to evade
/// automated static decompilers (Ghidra, Hopper, IDA Pro) and dynamic instrumentation (Frida, Cycript).
public final class BayanRuntimeIntegrityGuard {
    public static let shared = BayanRuntimeIntegrityGuard()

    public private(set) var isPipelineAnomalous: Bool = false
    public private(set) var diagnosticFlags: UInt32 = 0

    private init() {
        performSubsystemAudit()
    }

    // MARK: - Unified Silent Subsystem Audit
    /// Obfuscated entrypoint called during core engine startup
    @discardableResult
    public func performSubsystemAudit() -> Bool {
        var flags: UInt32 = 0

        // Probe 1: VFS Boundary Isolation Check
        if !validateVFSBoundaryIsolation() {
            flags |= (1 << 0)
        }

        // Probe 2: Mach-O Dylib Image Table Inspection
        if !auditMachOImageHierarchy() {
            flags |= (1 << 1)
        }

        // Probe 3: Known Package Hierarchy Probing
        if !probeKnownSubsystemSignatures() {
            flags |= (1 << 2)
        }

        // Probe 4: Kernel Process Diagnostics (P_TRACED Debugger)
        if probeSysctlDiagnostics() {
            flags |= (1 << 3)
        }

        // Probe 5: Custom Dynamic URL Protocol Scheme Probing
        if probeDynamicProtocolHandlers() {
            flags |= (1 << 4)
        }

        self.diagnosticFlags = flags
        self.isPipelineAnomalous = (flags != 0)

        #if DEBUG
        if isPipelineAnomalous {
            print("🛡️ [RuntimeGuard] Subsystem Audit Flags: 0x\(String(flags, radix: 16))")
        }
        #endif

        return !isPipelineAnomalous
    }

    // MARK: - Probe 1: VFS Boundary Isolation Check
    /// Attempts write outside standard sandbox boundary
    private func validateVFSBoundaryIsolation() -> Bool {
        let testPath = "/private/bayan_entropy_\(UUID().uuidString.prefix(8)).tmp"
        do {
            try "canary".write(toFile: testPath, atomically: true, encoding: .utf8)
            // If write succeeded outside sandbox, system is jailbroken
            try? FileManager.default.removeItem(atPath: testPath)
            return false
        } catch {
            // Expected: EPERM or sandbox denial
            return true
        }
    }

    // MARK: - Probe 2: Mach-O Dynamic Library Table Inspection
    /// Iterates loaded dylibs at runtime searching for Frida, Cycript, Substrate, Substitute
    private func auditMachOImageHierarchy() -> Bool {
        let suspiciousTokens = [
            "frida",
            "cycript",
            "substrate",
            "substitute",
            "cydia",
            "hooker",
            "sslkillswitch",
            "shadow",
            "choicy",
            "libsparkapplist"
        ]

        let count = _dyld_image_count()
        for i in 0..<count {
            guard let rawName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: rawName).lowercased()
            for token in suspiciousTokens {
                if name.contains(token) {
                    return false
                }
            }
        }
        return true
    }

    // MARK: - Probe 3: Known Subsystem Signatures
    /// Inspects existence of root files and symlinks
    private func probeKnownSubsystemSignatures() -> Bool {
        // Obfuscated string table decoded at runtime
        let paths = [
            decodeObfuscatedPath([47, 65, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 115, 47, 67, 121, 100, 105, 97, 46, 97, 112, 112]), // /Applications/Cydia.app
            decodeObfuscatedPath([47, 65, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 115, 47, 83, 105, 108, 101, 111, 46, 97, 112, 112]), // /Applications/Sileo.app
            decodeObfuscatedPath([47, 117, 115, 114, 47, 115, 98, 105, 110, 47, 115, 115, 104, 100]), // /usr/sbin/sshd
            decodeObfuscatedPath([47, 98, 105, 110, 47, 98, 97, 115, 104]), // /bin/bash
            decodeObfuscatedPath([47, 101, 116, 99, 47, 97, 112, 116]), // /etc/apt
            decodeObfuscatedPath([47, 112, 114, 105, 118, 97, 116, 101, 47, 118, 97, 114, 47, 108, 105, 98, 47, 97, 112, 116, 47]), // /private/var/lib/apt/
            decodeObfuscatedPath([47, 76, 105, 98, 114, 97, 114, 121, 47, 77, 111, 98, 105, 108, 101, 83, 117, 98, 115, 116, 114, 97, 116, 101, 47]) // /Library/MobileSubstrate/
        ]

        let fm = FileManager.default
        for path in paths {
            if fm.fileExists(atPath: path) {
                return false
            }

            // Check symlink resolution
            var statInfo = stat()
            if lstat(path, &statInfo) == 0 {
                return false
            }
        }
        return true
    }

    // MARK: - Probe 4: Kernel Process Diagnostics (Debugger Detection)
    /// Checks if process is being traced/debugged via sysctl
    private func probeSysctlDiagnostics() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }

        // P_TRACED flag: 0x00000800
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // MARK: - Probe 5: Custom Dynamic URL Protocol Scheme Probing
    private func probeDynamicProtocolHandlers() -> Bool {
        guard let cydiaUrl = URL(string: "cydia://package/com.bayan"),
              let sileoUrl = URL(string: "sileo://package/com.bayan"),
              let zbraUrl = URL(string: "zbra://package/com.bayan") else {
            return false
        }

        #if os(iOS)
        let app = UIApplication.shared
        if app.canOpenURL(cydiaUrl) || app.canOpenURL(sileoUrl) || app.canOpenURL(zbraUrl) {
            return true
        }
        #endif

        return false
    }

    // MARK: - Utility: Obfuscated Path Byte Decoder
    private func decodeObfuscatedPath(_ bytes: [UInt8]) -> String {
        String(bytes: bytes, encoding: .utf8) ?? ""
    }
}
