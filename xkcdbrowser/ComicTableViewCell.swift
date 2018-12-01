//
//  ComicTableViewCell.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/29/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit

/**
 Used to show a comic in the comics table.
 */
class ComicTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "ComicCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let view = UIView()
        view.backgroundColor = .xkcdBlueWithAlpha
        selectedBackgroundView = view
        
        // Image view styling.
        imageView?.layer.shadowColor = UIColor.black.cgColor
        imageView?.layer.shadowRadius = 2
        imageView?.clipsToBounds = false
        imageView?.layer.shadowOpacity = 0.1
        imageView?.layer.shadowOffset = CGSize(width: 2, height: 2)
    }
    
    func setComicImage(_ image: UIImage) {
        imageView?.image = ComicTableViewCell.thumbnailFromImage(image)
    }
    
    // Apply a size transform, padding, and random rotation to the image.
    private static func thumbnailFromImage(_ image: UIImage) -> UIImage {
        let baseThumbnailSize: Double = 100
        let maximumRotationDegree: Double = 20
        let radians = maximumRotationDegree * .pi / 180
        let thumbnailSizeAfterRotation = (sin(radians) + cos(radians)) * baseThumbnailSize
        let thumbnailSize = CGSize(width: thumbnailSizeAfterRotation, height: thumbnailSizeAfterRotation)
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0)
        
        // Apply a random rotation around the center of the image.
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: thumbnailSize.width / 2, y: thumbnailSize.height / 2)
        var randomDegree = 0
        for _ in 0..<10 {
            randomDegree = Int(arc4random_uniform(UInt32(2 * maximumRotationDegree))) - Int(maximumRotationDegree)
            if randomDegree != 0 {
                break
            }
        }
        context?.rotate(by: CGFloat(randomDegree) * .pi / 180)
        context?.translateBy(x: -thumbnailSize.width / 2, y: -thumbnailSize.height / 2)
        
        // Scale input image to fit base thumbnail size.
        let scaledImageSize: CGSize
        if image.size.width / image.size.height * CGFloat(baseThumbnailSize) > CGFloat(baseThumbnailSize) {
            // Scale the width to fit.
            scaledImageSize = CGSize(width: CGFloat(baseThumbnailSize),
                                     height: image.size.height / image.size.width * CGFloat(baseThumbnailSize))
        } else {
            // Scale the height to fit.
            scaledImageSize = CGSize(width: image.size.width / image.size.height * CGFloat(baseThumbnailSize),
                                     height: CGFloat(baseThumbnailSize))
        }
        
        let scaledImageRect = CGRect(x: (thumbnailSize.width - scaledImageSize.width) / 2,
                                     y: (thumbnailSize.height - scaledImageSize.height) / 2,
                                     width: scaledImageSize.width,
                                     height: scaledImageSize.height)
        
        image.draw(in: scaledImageRect)
        
        context?.restoreGState()
        
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return thumbnailImage
    }
}
