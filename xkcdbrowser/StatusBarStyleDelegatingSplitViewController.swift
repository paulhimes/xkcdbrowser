//
//  StatusBarStyleDelegatingSplitViewController.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/29/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit

class StatusBarStyleDelegatingSplitViewController: UISplitViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return viewControllers.first?.preferredStatusBarStyle ?? .default
    }
}
