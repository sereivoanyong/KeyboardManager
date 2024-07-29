//
//  UIScrollView+Keyboard.swift
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit

private var shouldIgnoreAdjustmentsForKeyboardKey: Void?
private var isBeingAdjustedForKeyboardKey: Void?

extension UIScrollView {

  /// If YES, then scrollview will ignore scrolling (simply not scroll it) for adjusting textfield position. Default is NO.
  public var shouldIgnoreAdjustmentsForKeyboard: Bool {
    get { return objc_getAssociatedValue(self, &shouldIgnoreAdjustmentsForKeyboardKey) ?? false }
    set { objc_setAssociatedValue(self, &shouldIgnoreAdjustmentsForKeyboardKey, newValue) }
  }

  public var isBeingAdjustedForKeyboard: Bool {
    get { return objc_getAssociatedValue(self, &isBeingAdjustedForKeyboardKey) ?? false }
    set { objc_setAssociatedValue(self, &isBeingAdjustedForKeyboardKey, newValue) }
  }
}
