//
//  ComicTableViewCell.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/29/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit

class ComicTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let view = UIView()
        view.backgroundColor = UIColor(named: "xkcdBlue")
        selectedBackgroundView = view
    }
}