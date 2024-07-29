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

  public private(set) var isKeyboardHidden: Bool = true

  public private(set) var keyboardUserInfo: KeyboardUserInfo?

  public private(set) var textInputView: TextInputView?

  public var automaticallyAddsToolbar: Bool = true

  public var toolbarUsesTextInputViewTintColor: Bool = true

  public var playsInputClickOnToolbarActionsTriggered: Bool = true

  public var viewControllerClassesToDisableToolbar: [UIViewController.Type] = []

  public var isTapOutsideToResignEnabled: Bool = true {
    didSet {
      if let textInputView {
        tapOutsideToResignGestureRecognizer.isEnabled = isTapOutsideToResignEnabled(for: textInputView)
      }
    }
  }

  /// Enabled classes to forcefully enable `isTapOutsideToResignEnabled` property.
  /// If same class is added in `viewControllerClassesToDisableTapToResign`, then `viewControllerClassesToEnableTapToResign` will be ignored.
  public var viewControllerClassesToEnableTapOutsideToResign: [UIViewController.Type] = []

  /// Disabled classes to ignore `isTapOutsideToResignEnabled` property.
  public var viewControllerClassesToDisableTapOutsideToResign: [UIViewController.Type] = [
    UIAlertController.self,
    UIInputViewController.self
  ]

  public var viewClassesToIgnoreTapOutsideToResign: [UIView.Type] = [
    UIControl.self,
    UINavigationBar.self
  ]

  private weak var scrollView: UIScrollView?

  private var oldScrollViewContentInsetBottom: CGFloat?

  private var oldScrollViewScrollIndicatorInsetBottom: CGFloat?

  lazy public private(set) var tapOutsideToResignGestureRecognizer: UITapGestureRecognizer = {
    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapOutsideToResign(_:)))
    gestureRecognizer.cancelsTouchesInView = false
    gestureRecognizer.delegate = self
    gestureRecognizer.isEnabled = false
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
    isKeyboardHidden = false

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
    isKeyboardHidden = true

    keyboardUserInfo = KeyboardUserInfo(notification: notification)

    if let scrollView {
      let restore: () -> Void = { [unowned self] in
        if let oldScrollViewContentInsetBottom {
          scrollView.contentInset.bottom = oldScrollViewContentInsetBottom
        }
        if let oldScrollViewScrollIndicatorInsetBottom {
          scrollView.verticalScrollIndicatorInsets.bottom = oldScrollViewScrollIndicatorInsetBottom
        }
      }
      if let keyboardUserInfo {
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
    if let textInputView {
      if let overrideKeyboardAppearance {
        if textInputView.responds(to: #selector(setter: UITextInputTraits.keyboardAppearance)) {
          textInputView.perform(#selector(setter: UITextInputTraits.keyboardAppearance), with: overrideKeyboardAppearance)
        }
        textInputView.reloadInputViews()
      }

      reloadToolbar(for: textInputView)

      tapOutsideToResignGestureRecognizer.isEnabled = isTapOutsideToResignEnabled(for: textInputView)
      textInputView.window?.addGestureRecognizer(tapOutsideToResignGestureRecognizer)
    }
  }

  @objc private func textDidEndEditing(_ notification: Notification) {
    textInputView?.window?.removeGestureRecognizer(tapOutsideToResignGestureRecognizer)
    textInputView = nil
  }

  // MARK: Toolbar

  func reloadToolbar(for textInputView: TextInputView) {
    let addsToolbar: Bool
    if automaticallyAddsToolbar {
      if let viewController = textInputView.owningViewController {
        addsToolbar = !viewControllerClassesToDisableToolbar.contains(where: viewController.isKind(of:))
      } else {
        addsToolbar = true
      }
    } else {
      addsToolbar = false
    }
    if addsToolbar {
      addToolbarIfNeeded(for: textInputView)
    } else {
      removeToolbars(in: textInputView.owningViewController)
    }
  }

  @discardableResult
  func addToolbarIfNeeded(for textInputView: TextInputView) -> Bool {
    guard textInputView.inputAccessoryView == nil else {
      return false
    }
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
      if toolbar.title?.isEmpty ?? true {
        let placeholderGetter = #selector(getter: UITextField.placeholder)
        if textInputView.responds(to: placeholderGetter) {
          toolbar.title = textInputView.perform(placeholderGetter)?.takeUnretainedValue() as? String
        }
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

  func removeToolbars(in viewController: UIViewController?) {
    guard let viewController else { return }
    let inputAccessoryViewSetter = #selector(setter: UITextField.inputAccessoryView)
    let siblings = viewController.view.findTextInputViewsRecursively()
    for sibling in siblings {
      guard sibling.responds(to: inputAccessoryViewSetter) && sibling.inputAccessoryView is KeyboardToolbar else { continue }
      sibling.perform(inputAccessoryViewSetter, with: nil)
      sibling.reloadInputViews()
    }
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

    guard let textInputView, let viewController = textInputView.owningViewController else {
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

    guard let textInputView, let viewController = textInputView.owningViewController else {
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
    guard let keyboardUserInfo, let textInputView, let scrollView = textInputView.scrollViewForAdjustments(), let window = textInputView.window else { return }

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
    if bottomScrollIndicatorAdjustment > scrollView.verticalScrollIndicatorInsets.bottom {
      oldScrollViewScrollIndicatorInsetBottom = scrollView.verticalScrollIndicatorInsets.bottom
      adjustmentHandlers.append {
        scrollView.verticalScrollIndicatorInsets.bottom = bottomScrollIndicatorAdjustment
      }
    }
    keyboardUserInfo.animate {
      for adjustmentHandler in adjustmentHandlers {
        adjustmentHandler()
      }
    }
  }

  private func isTapOutsideToResignEnabled(for textInputView: TextInputView) -> Bool {
    var isEnabled = isTapOutsideToResignEnabled
    if var textInputViewController = textInputView.owningViewController {

      // If it is searchBar textField embedded in Navigation Bar
      if let textField = textInputView as? UITextField, textField.isSearchBarTextField,
         let navigationController = textInputViewController as? UINavigationController,
         let topViewController = navigationController.topViewController {
        textInputViewController = topViewController
      }

      // If viewController is kind of enable viewController class, then assuming resignOnTouchOutside is enabled.
      if !isEnabled && viewControllerClassesToEnableTapOutsideToResign.contains(where: { textInputViewController.isKind(of: $0) }) {
        isEnabled = true
      }

      if isEnabled {

        // If viewController is kind of disable viewController class,
        // then assuming resignOnTouchOutside is disable.
        if viewControllerClassesToDisableTapOutsideToResign.contains(where: { textInputViewController.isKind(of: $0) }) {
          isEnabled = false
        }

        // Special Controllers
        if isEnabled {

          let className = "\(type(of: textInputViewController))"

          // _UIAlertControllerTextFieldViewController
          if className.contains("UIAlertController") && className.hasSuffix("TextFieldViewController") {
            isEnabled = false
          }
        }
      }
    }
    return isEnabled
  }

  @objc private func tapOutsideToResign(_ gestureRecognizer: UITapGestureRecognizer) {
    if gestureRecognizer.state == .ended {
      textInputView?.resignFirstResponder()
    }
  }
}

extension KeyboardManager: UIGestureRecognizerDelegate {

  /** Note: returning YES is guaranteed to allow simultaneous recognition. returning NO is not guaranteed to prevent simultaneous recognition, as the other gesture's delegate may return YES. */
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if let view = touch.view {
      for viewClass in viewClassesToIgnoreTapOutsideToResign where view.isKind(of: viewClass) {
        return false
      }
      if let selectionInfo = view.selectionInfo() {
        switch selectionInfo {
        case .collection(let collectionView, let indexPath):
          return !(collectionView.delegate?.collectionView?(collectionView, shouldSelectItemAt: indexPath) ?? true)
        case .table(let tableView, let indexPath):
          return !(tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath) != nil)
        }
      }
    }
    return true
  }
}
