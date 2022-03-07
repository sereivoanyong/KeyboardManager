// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "KeyboardManager",
  platforms: [
    .iOS(.v11),
  ],
  products: [
    .library(name: "KeyboardManager", targets: ["KeyboardManager"]),
  ],
  targets: [
    .target(name: "KeyboardManager"),
  ]
)
