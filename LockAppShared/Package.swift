// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LockAppShared",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "LockAppShared",
            targets: ["LockAppShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1")
    ],
    targets: [
        .target(
            name: "LockAppShared",
            dependencies: ["Alamofire"])
    ]
) 
