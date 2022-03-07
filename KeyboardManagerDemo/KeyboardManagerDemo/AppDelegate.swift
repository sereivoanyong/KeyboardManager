//
//  AppDelegate.swift
//  KeyboardManagerDemo
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit
import KeyboardManager

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    _ = KeyboardManager.shared
    return true
  }
}
