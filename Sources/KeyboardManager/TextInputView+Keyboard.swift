//
//  TextInputView+Keyboard.swift
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit
import ObjectiveC

private var keyboardToolbarKey: Void?

extension UITextInputTraits where Self: UIView {

  var keyboardToolbar: KeyboardToolbar {
    if let toolbar = inputAccessoryView as? KeyboardToolbar ?? objc_getAssociatedObject(self, &keyboardToolbarKey) as? KeyboardToolbar {
      return toolbar
    }
    let toolbar = KeyboardToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
    objc_setAssociatedObject(self, &keyboardToolbarKey, toolbar, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return toolbar
  }

  func scrollViewForAdjustments() -> UIScrollView? where Self: UITextInputTraits {
    var scrollView = superview(of: UIScrollView.self)
    while let targetScrollView = scrollView {
      if targetScrollView.isScrollEnabled && !targetScrollView.shouldIgnoreAdjustmentsForKeyboard {
        return targetScrollView
      } else {
        scrollView = targetScrollView.superview(of: UIScrollView.self)
      }
    }
    return scrollView
  }

  var _canBecomeFirstResponder: Bool {
    var canBecomeFirstResponder = false
    if let textField = self as? UITextField {
      canBecomeFirstResponder = textField.isEnabled && !textField.isAlertViewTextField && !textField.isSearchBarTextField
    } else if let textView = self as? UITextView {
      canBecomeFirstResponder = textView.isEditable
    }
    if canBecomeFirstResponder {
      canBecomeFirstResponder = isUserInteractionEnabled && !isHidden && alpha > 0.0
    }
    return canBecomeFirstResponder
  }
}

extension UIView {

  final func findTextInputViewsRecursively() -> [TextInputView] {
    var textInputViews: [TextInputView] = []
    for subview in subviews {
      if let textInputView = subview as? TextInputView, textInputView._canBecomeFirstResponder {
        textInputViews.append(textInputView)
      }
      // Sometimes there are hidden or disabled views and textField inside them still recorded, so we added some more validations here (Bug ID: #458)
      // Uncommented else (Bug ID: #625)
      else if !subview.subviews.isEmpty && isUserInteractionEnabled && !isHidden && alpha > 0.0 {
        for deepView in subview.findTextInputViewsRecursively() {
          textInputViews.append(deepView)
        }
      }
    }

    // Subviews are returning in opposite order. Sorting according the frames 'y'.
    return textInputViews.sorted { view1, view2 in
      let frame1 = view1.convert(view1.bounds, to: self)
      let frame2 = view2.convert(view2.bounds, to: self)
      if frame1.minY != frame2.minY {
        return frame1.minY < frame2.minY
      } else {
        return frame1.minX < frame2.minX
      }
    }
  }
}
