// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "KeyboardManager",
  products: [
    .library(name: "KeyboardManager", targets: ["KeyboardManager"])
  ],
  targets: [
    .target(name: "KeyboardManager")
  ]
)
