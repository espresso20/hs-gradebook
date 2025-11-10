// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GradebookApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GradebookApp",
            targets: ["GradebookApp"]
        )
    ],
    dependencies: [
        // Google Sign-In SDK
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "GradebookApp",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ]
        )
    ]
)
