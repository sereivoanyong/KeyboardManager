//
//  UIView+Keyboard.swift
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit

enum SelectionInfo {

  case collection(UICollectionView, IndexPath)

  case table(UITableView, IndexPath)
}

extension UIView {

  func selectionInfo() -> SelectionInfo? {
    switch self {
    case let cell as UICollectionViewCell:
      if let collectionView = cell.superview(of: UICollectionView.self), let indexPath = collectionView.indexPath(for: cell) {
        return .collection(collectionView, indexPath)
      }
    case let cell as UITableViewCell:
      if let tableView = cell.superview(of: UITableView.self), let indexPath = tableView.indexPath(for: cell) {
        return .table(tableView, indexPath)
      }
    default:
      break
    }
    if let superview {
      return superview.selectionInfo()
    }
    return nil
  }

  func superview<T: UIView>(of type: T.Type) -> T? {
    if let superview {
      if let superview = superview as? T {
        return superview
      }
      return superview.superview(of: type)
    }
    return nil
  }

  /// The view controller that owns this view.
  var owningViewController: UIViewController? {
    if let next {
      if let viewController = next as? UIViewController {
        return viewController
      }
      if let view = next as? UIView {
        return view.owningViewController
      }
    }
    return nil
  }

  /// Returns the view controller that is actually the parent of the owning view controller.
  /// Most of the time it's the `owningViewController` which actually contains it, but result may be different if its `owningViewController` is added as `childViewController` of another view controller.
  final func parentOwningViewController() -> UIViewController? {
    guard var target = owningViewController else {
      return nil
    }

    if var navigationController = target.navigationController {
      while let parent = navigationController.navigationController {
        navigationController = parent
      }

      var parent: UIViewController = navigationController

      while let currentParent = parent.parent,
            !(currentParent is UINavigationController) && !(currentParent is UITabBarController) && !(currentParent is UISplitViewController) {
        parent = currentParent
      }

      if navigationController == parent {
        return navigationController.topViewController
      } else {
        return parent
      }

    } else if let tabBarController = target.tabBarController {

      if let navigationController = tabBarController.selectedViewController as? UINavigationController {
        return navigationController.topViewController
      } else {
        return tabBarController.selectedViewController
      }

    } else {
      while let parentController = target.parent,
            !(parentController is UINavigationController) && !(parentController is UITabBarController) && !(parentController is UISplitViewController) {
        target = parentController
      }

      return target
    }
  }
}
