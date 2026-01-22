import Foundation

class OSPackageInfo {

    public static func get() -> PackageInfo {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(macOS) || os(visionOS)
        return PackageInfo.getApplePackage()
        #elseif os(Linux)
        return PackageInfo.getLinuxPackage()
        #elseif os(Windows)
        return PackageInfo.getWindowsPackage()
        #elseif os(WASI)
        // TODO: have a better response in this case
        return PackageInfo(
            appName: "unknown", 
            version: "unknown", 
            buildNumber: "unknown", 
            packageName: "unknown"
        )
        #endif
    }
}
