//
//  DetailViewController.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
//    private let margin: CGFloat = 8
    
    private var containerSize: CGSize {
//        return view.bounds.size
        let containerWidth = view.bounds.size.width - view.safeAreaInsets.left - view.safeAreaInsets.right
        let containerHeight = view.bounds.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        return CGSize(width: containerWidth, height: containerHeight)
    }
    
    func configureView() {
        guard let comic = detailItem else { return }
        title = comic.safeTitle
        
        URLSession.shared.dataTask(with: comic.image) { [weak self] (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.updateZoomScales()
            }
        }.resume()
    }
    
    // Update minimum zoom scale based on image size vs scrollview size.
    fileprivate func updateZoomScales() {
        guard let image = imageView.image else {
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 1
            return
        }

        let widthScale = containerSize.width / image.size.width
        let heightScale = containerSize.height / image.size.height
        let minScale = min(widthScale, heightScale)
        
        let maxScale = max(widthScale, heightScale)
        
        scrollView.minimumZoomScale = min(1, minScale)
        scrollView.maximumZoomScale = maxScale
        scrollView.zoomScale = minScale
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateZoomScales()
        updateConstraints()
    }

    var detailItem: ManagedComic? {
        didSet {
            configureView()
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints()
    }
    
    private func updateConstraints() {
        guard let imageSize = imageView.image?.size else {
            imageViewLeadingConstraint.constant = 0
            imageViewTrailingConstraint.constant = 0
            imageViewTopConstraint.constant = 0
            imageViewBottomConstraint.constant = 0
            return
        }

        let xPadding = max(0, (containerSize.width - (imageSize.width * scrollView.zoomScale)) / 2)
        imageViewLeadingConstraint.constant = xPadding
        imageViewTrailingConstraint.constant = xPadding

        let yPadding = max(0, (containerSize.height - (imageSize.height * scrollView.zoomScale)) / 2)
        imageViewTopConstraint.constant = yPadding
        imageViewBottomConstraint.constant = yPadding

        NSLog("container size = (\(containerSize.width),\(containerSize.height)), image size = (\(imageSize.width),\(imageSize.height)), scrollView zoom = \(scrollView.zoomScale), scaled image size = (\(imageSize.width * scrollView.zoomScale),\(imageSize.height * scrollView.zoomScale)), xPadding = \(xPadding), yPadding = \(yPadding)")

        view.layoutIfNeeded()
    }
}
