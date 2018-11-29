//
//  StatusBarStyleDelegatingNavigationController.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/29/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit

class StatusBarStyleDelegatingNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}
