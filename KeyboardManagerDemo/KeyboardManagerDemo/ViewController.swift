//
//  ViewController.swift
//  KeyboardManagerDemo
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit

final class ViewController: UIViewController {

  @IBOutlet weak private var scrollView: UIScrollView!
  @IBOutlet weak private var button: UIButton?

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.searchController = UISearchController(searchResultsController: nil)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let button {
      scrollView.contentInset.bottom = button.frame.height + 16 * 2
    }
  }
}
