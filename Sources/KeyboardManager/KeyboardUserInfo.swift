//
//  KeyboardUserInfo.swift
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit

public struct KeyboardUserInfo {

  public let frameBegin: CGRect
  public let frameEnd: CGRect
  public let animationDuration: TimeInterval
  public let animationCurve: UIView.AnimationCurve
  public let isLocal: Bool

  init?(notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let frameBegin = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
      let frameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
      let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
      let animationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UIView.AnimationCurve.RawValue).flatMap(UIView.AnimationCurve.init(rawValue:)),
      let isLocal = userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool
    else {
      return nil
    }
    self.frameBegin = frameBegin
    self.frameEnd = frameEnd
    self.animationDuration = animationDuration
    self.animationCurve = animationCurve
    self.isLocal = isLocal
  }

  @discardableResult
  public func animate(animations: @escaping () -> Void) -> UIViewPropertyAnimator {
    let animator = UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve, animations: animations)
    animator.startAnimation()
    return animator
  }
}
