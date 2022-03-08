//
//  KeyboardManager.swift
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit

/// The `UITextField` and `UITextView`
public typealias TextInputView = UIView & UITextInputTraits

final public class KeyboardManager: NSObject {

  public static let shared: KeyboardManager = .init()

  public var overrideKeyboardAppearance: UIKeyboardAppearance?

  public private(set) var isKeyboardShown: Bool = false

  public private(set) var keyboardUserInfo: KeyboardUserInfo?

  public private(set) var textInputView: TextInputView?

  public var automaticallyAddsToolbar: Bool = true

  public var toolbarUsesTextInputViewTintColor: Bool = true

  public var playsInputClickOnToolbarActionsTriggered: Bool = true

  private weak var scrollView: UIScrollView?

  private var oldScrollViewContentInsetBottom: CGFloat?

  private var oldScrollViewScrollIndicatorInsetBottom: CGFloat?

  lazy public private(set) var gestureRecognizerToResignFirstResponder: UITapGestureRecognizer = {
    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapToResignFirstResponder(_:)))
    gestureRecognizer.cancelsTouchesInView = false
    gestureRecognizer.delegate = self
    return gestureRecognizer
  }()

  override init() {
    super.init()

    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)

    register(didBeginEditingNotification: UITextField.textDidBeginEditingNotification, didEndEditingNotification: UITextField.textDidEndEditingNotification)
    register(didBeginEditingNotification: UITextView.textDidBeginEditingNotification, didEndEditingNotification: UITextView.textDidEndEditingNotification)
  }

  public func register(didBeginEditingNotification: Notification.Name, didEndEditingNotification: Notification.Name) {
    NotificationCenter.default.addObserver(self, selector: #selector(textDidBeginEditing(_:)), name: didBeginEditingNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(textDidEndEditing(_:)), name: didEndEditingNotification, object: nil)
  }

  public func unregister(didBeginEditingNotification: Notification.Name, didEndEditingNotification: Notification.Name) {
    NotificationCenter.default.removeObserver(self, name: didBeginEditingNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: didEndEditingNotification, object: nil)
  }

  // MARK: Keyboard Notifications

  @objc private func keyboardWillShow(_ notification: Notification) {
    isKeyboardShown = true

    let oldKeyboardUserInfo = keyboardUserInfo
    keyboardUserInfo = KeyboardUserInfo(notification: notification)
    if keyboardUserInfo?.frameEnd != oldKeyboardUserInfo?.frameEnd {
      layout()
    }
  }

  @objc private func keyboardDidShow(_ notification: Notification) {
    layout()
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    isKeyboardShown = false

    keyboardUserInfo = KeyboardUserInfo(notification: notification)

    if let scrollView = scrollView {
      let restore: () -> Void = { [unowned self] in
        if let oldScrollViewContentInsetBottom = oldScrollViewContentInsetBottom {
          scrollView.contentInset.bottom = oldScrollViewContentInsetBottom
        }
        if let oldScrollViewScrollIndicatorInsetBottom = oldScrollViewScrollIndicatorInsetBottom {
          scrollView.scrollIndicatorInsets.bottom = oldScrollViewScrollIndicatorInsetBottom
        }
      }
      if let keyboardUserInfo = keyboardUserInfo {
        keyboardUserInfo.animate(animations: restore)
      } else {
        restore()
      }
      scrollView.isBeingAdjustedForKeyboard = false
    }

    scrollView = nil
    oldScrollViewContentInsetBottom = nil
    oldScrollViewScrollIndicatorInsetBottom = nil
  }

  @objc private func keyboardDidHide(_ notification: Notification) {
    keyboardUserInfo = nil
  }

  // MARK: Text Input View Notifications

  @objc private func textDidBeginEditing(_ notification: Notification) {
    textInputView = notification.object as? TextInputView
    if let textInputView = textInputView {
      if let overrideKeyboardAppearance = overrideKeyboardAppearance {
        if textInputView.responds(to: #selector(setter: UITextInputTraits.keyboardAppearance)) {
          textInputView.perform(#selector(setter: UITextInputTraits.keyboardAppearance), with: overrideKeyboardAppearance)
        }
        textInputView.reloadInputViews()
      }

      if automaticallyAddsToolbar && textInputView.inputAccessoryView == nil {
        configureToolbar(for: textInputView)
      }
      textInputView.window?.addGestureRecognizer(gestureRecognizerToResignFirstResponder)
    }
  }

  @objc private func textDidEndEditing(_ notification: Notification) {
    textInputView?.window?.removeGestureRecognizer(gestureRecognizerToResignFirstResponder)
    textInputView = nil
  }

  // MARK: Toolbar

  @discardableResult
  func configureToolbar(for textInputView: TextInputView) -> Bool {
    if let textField = textInputView as? UITextField, (textField.isAlertViewTextField || textField.isSearchBarTextField) {
      return false
    }
    let inputAccessoryViewSetter = #selector(setter: UITextField.inputAccessoryView)
    guard textInputView.responds(to: inputAccessoryViewSetter), let viewController = textInputView.owningViewController else {
      return false
    }
    let siblings = viewController.view.findTextInputViewsRecursively()
    let toolbar = textInputView.keyboardToolbar
    // Configure title
    do {
      let placeholderGetter = #selector(getter: UITextField.placeholder)
      if textInputView.responds(to: placeholderGetter) {
        toolbar.title = textInputView.perform(placeholderGetter)?.takeUnretainedValue() as? String
      }
    }
    // Configure done/next/previous button items
    do {
      toolbar.doneButtonItem.target = self
      toolbar.doneButtonItem.action = #selector(done(_:))
      toolbar.nextButtonItem.target = self
      toolbar.nextButtonItem.action = #selector(goToNext(_:))
      toolbar.nextButtonItem.isEnabled = siblings.last !== textInputView
      toolbar.previousButtonItem.target = self
      toolbar.previousButtonItem.action = #selector(goToPrevious(_:))
      toolbar.previousButtonItem.isEnabled = siblings.first !== textInputView
    }
    // Configure keyboard appearance
    if let keyboardAppearance = textInputView.keyboardAppearance {
      if keyboardAppearance == .dark {
        toolbar.barStyle = .black
      } else {
        toolbar.barStyle = .default
      }
    }
    if toolbarUsesTextInputViewTintColor {
      toolbar.tintColor = toolbarUsesTextInputViewTintColor ? textInputView.tintColor : nil
    }
    textInputView.perform(inputAccessoryViewSetter, with: toolbar)
    return true
  }

  @objc private func done(_ sender: UIBarButtonItem) {
    if playsInputClickOnToolbarActionsTriggered {
      UIDevice.current.playInputClick()
    }

    textInputView?.resignFirstResponder()
  }

  @objc private func goToNext(_ sender: UIBarButtonItem) {
    if playsInputClickOnToolbarActionsTriggered {
      UIDevice.current.playInputClick()
    }

    guard let textInputView = textInputView, let viewController = textInputView.owningViewController else {
      return
    }
    let siblings = viewController.view.findTextInputViewsRecursively()
    guard let index = siblings.firstIndex(where: { $0 === textInputView }), index < siblings.count - 1 else {
      return
    }
    let nextTextInputView = siblings[index + 1]
    let hasBecomeFirstResponder = nextTextInputView.becomeFirstResponder()
    // If it refuses then becoming previous textFieldView as first responder again.
    if !hasBecomeFirstResponder {
      // If next field refuses to become first responder then restoring old textField as first responder.
      textInputView.becomeFirstResponder()
    }
  }

  @objc private func goToPrevious(_ sender: UIBarButtonItem) {
    if playsInputClickOnToolbarActionsTriggered {
      UIDevice.current.playInputClick()
    }

    guard let textInputView = textInputView, let viewController = textInputView.owningViewController else {
      return
    }
    let siblings = viewController.view.findTextInputViewsRecursively()
    guard let index = siblings.firstIndex(where: { $0 === textInputView }), index > 0 else {
      return
    }
    let previousTextInputView = siblings[index - 1]
    let hasBecomeFirstResponder = previousTextInputView.becomeFirstResponder()
    // If it refuses then becoming previous textFieldView as first responder again.
    if !hasBecomeFirstResponder {
      // If next field refuses to become first responder then restoring old textField as first responder.
      textInputView.becomeFirstResponder()
    }
  }

  // MARK: Layout

  func layout() {
    guard
      let keyboardUserInfo = keyboardUserInfo,
      let textInputView = textInputView,
      let scrollView = textInputView.scrollViewForAdjustments(),
      let window = textInputView.window
    else {
      return
    }

    self.scrollView = scrollView
    scrollView.isBeingAdjustedForKeyboard = true

    let windowKeyboardFrame = keyboardUserInfo.frameEnd.intersection(window.frame)
    var adjustmentHandlers: [() -> Void] = []
    let bottomContentAdjustment = windowKeyboardFrame.height - scrollView.safeAreaInsets.bottom
    if bottomContentAdjustment > scrollView.contentInset.bottom {
      oldScrollViewContentInsetBottom = scrollView.contentInset.bottom
      adjustmentHandlers.append {
        scrollView.contentInset.bottom = bottomContentAdjustment
      }
    }
    let bottomScrollIndicatorAdjustment = windowKeyboardFrame.height - scrollView.safeAreaInsets.bottom
    if bottomScrollIndicatorAdjustment > scrollView.scrollIndicatorInsets.bottom {
      oldScrollViewScrollIndicatorInsetBottom = scrollView.scrollIndicatorInsets.bottom
      adjustmentHandlers.append {
        scrollView.scrollIndicatorInsets.bottom = bottomScrollIndicatorAdjustment
      }
    }
    keyboardUserInfo.animate {
      for adjustmentHandler in adjustmentHandlers {
        adjustmentHandler()
      }
    }
  }
}

extension KeyboardManager: UIGestureRecognizerDelegate {

  @objc private func handleTapToResignFirstResponder(_ gestureRecognizer: UITapGestureRecognizer) {
    if gestureRecognizer.state == .ended {
      textInputView?.resignFirstResponder()
    }
  }

  /** Note: returning YES is guaranteed to allow simultaneous recognition. returning NO is not guaranteed to prevent simultaneous recognition, as the other gesture's delegate may return YES. */
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }
}
