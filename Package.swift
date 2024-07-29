// swift-tools-version:5.10

import PackageDescription

let package = Package(
  name: "KeyboardManager",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(name: "KeyboardManager", targets: ["KeyboardManager"])
  ],
  targets: [
    .target(name: "KeyboardManager")
  ]
)
