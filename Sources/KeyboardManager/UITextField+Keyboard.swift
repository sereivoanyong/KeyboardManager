//
//  UITextField+Keyboard.swift
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit

extension UITextField {

  /// Returns YES if the receiver object is UIAlertSheetTextField, otherwise return NO.
  var isAlertViewTextField: Bool {
    return findAlertController() != nil
  }

  func findAlertController() -> UIAlertController? {
    var responder = next
    while let currentResponder = responder {
      if let alertController = currentResponder as? UIAlertController {
        return alertController
      }
      responder = currentResponder.next
    }
    return nil
  }

  var isSearchBarTextField: Bool {
    return findSearchBar() != nil
  }

  /// Returns searchBar if receiver object is UISearchBarTextField, otherwise return nil.
  private func findSearchBar() -> UISearchBar? {
    var responder = next
    while let currentResponder = responder {
      if let searchBar = currentResponder as? UISearchBar {
        return searchBar
      }
      if currentResponder is UIViewController {
        return nil
      }
      responder = currentResponder.next
    }
    return nil
  }
}
