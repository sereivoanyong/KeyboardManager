//
//  KeyboardToolbar.swift
//
//  Created by Sereivoan Yong on 3/7/22.
//

import UIKit

final public class KeyboardToolbar: UIToolbar {

  public let titleLabel: UILabel
  public let titleButtonItem: UIBarButtonItem

  lazy public private(set) var doneButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)

  lazy public private(set) var nextButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.down"), style: .plain, target: nil, action: nil)
  lazy public private(set) var previousButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.up"), style: .plain, target: nil, action: nil)

  public var title: String? {
    get { return titleLabel.text }
    set { titleLabel.text = newValue }
  }

  public override init(frame: CGRect) {
    titleLabel = UILabel()
    titleLabel.font = .systemFont(ofSize: 13)
    titleLabel.textColor = .placeholderText
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleButtonItem = UIBarButtonItem(customView: titleLabel)
    super.init(frame: frame)

    items = [
      previousButtonItem, nextButtonItem,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      titleButtonItem,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      doneButtonItem
    ]
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
