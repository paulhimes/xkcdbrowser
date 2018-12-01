//
//  ComicDetailsViewController.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit

/**
 Displays the detailed information about a comic. Includes a zoomable / scrollable view of the image,
 sharing options, and tap-to-view alternate text and links if available.
 */
class ComicDetailsViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Main Image
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private var zoomDoubleTapGestureRecognizer: UITapGestureRecognizer!
    private let margin: CGFloat = 8 // Used to calculate minimum and maximum zoom scales.
    
    // MARK: - Details
    @IBOutlet private weak var moreDetailsView: UIView!
    @IBOutlet private weak var alternateTextLabel: UILabel!
    @IBOutlet private weak var linkButton: UIButton!
    @IBOutlet private var toggleTapGestureRecognizer: UITapGestureRecognizer!
    
    
    // The visible region of the scroll view.
    private var containerSize: CGSize {
        let containerWidth = view.bounds.size.width - view.safeAreaInsets.left - view.safeAreaInsets.right
        let containerHeight = view.bounds.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        return CGSize(width: containerWidth, height: containerHeight)
    }
    
    // The visible size of the image.
    private var scaledImageSize: CGSize {
        guard let imageSize = imageView.image?.size else {
            return .zero
        }
        return CGSize(width: imageSize.width * scrollView.zoomScale, height: imageSize.height * scrollView.zoomScale)
    }
    
    // The data model.
    var comic: ManagedComic? {
        didSet {
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        toggleTapGestureRecognizer.require(toFail: zoomDoubleTapGestureRecognizer)
        styleNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateZoomScales()
        updateConstraints()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // Synchronize the view with the data model.
    private func configureView() {
        guard let comic = comic else {
            // Empty state (only used on iPad)
            alternateTextLabel?.text = "Come back when you've chosen a comic to read."
            linkButton?.isHidden = true
            moreDetailsView?.alpha = 1
            return
        }
        title = comic.safeTitle
        
        moreDetailsView?.alpha = 0
        alternateTextLabel?.text = comic.alternateText
        linkButton?.isHidden = comic.link == nil
        
        // Download the high resolution version of the comic image.
        ComicFetcher.loadImageForURL(comic.image, highResolution: true) { [weak self] (image) in
            if let imageView = self?.imageView {
                imageView.image = image
                self?.updateZoomScales()
            }
        }
    }

    /**
     Update minimum and maximum zoom scales based on image size vs scrollview size.
     The minimum zoom is zoomed to fit (unless the image is even smaller).
     The maximum zoom is zoomed to fill.
     Auto zooms the image to it's minimum zoom scale.
     */
    private func updateZoomScales() {
        guard let image = imageView.image else {
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 1
            return
        }

        let widthScale = (containerSize.width - margin * 2) / image.size.width
        let heightScale = (containerSize.height - margin * 2) / image.size.height
        
        let minScale = min(widthScale, heightScale)
        let maxScale = max(widthScale, heightScale)
        
        scrollView.minimumZoomScale = min(1, minScale)
        scrollView.maximumZoomScale = maxScale
        scrollView.zoomScale = scrollView.minimumZoomScale
    }

    // Open the optional link in an external browser.
    @IBAction private func linkAction(_ sender: Any) {
        guard let link = comic?.link else { return }
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
    
    // Show / hide the details view.
    @IBAction private func toggleAction(_ sender: Any) {
        UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            guard let moreDetailsView = self?.moreDetailsView else { return }
            moreDetailsView.alpha = moreDetailsView.alpha < 1 ? 1 : 0
        }.startAnimation()
    }
    
    // Cycle through a set of useful zoom levels when the user double taps the image.
    @IBAction private func zoomAction(_ sender: Any) {
        guard moreDetailsView.alpha < 1 else { return }
        
        let zoomScaleStops = [scrollView.minimumZoomScale, 1, scrollView.maximumZoomScale].sorted { $0 < $1 }

        UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            guard let scrollView = self?.scrollView else { return }
            for zoomScaleStop in zoomScaleStops {
                if scrollView.zoomScale < zoomScaleStop {
                    scrollView.zoomScale = zoomScaleStop
                    break
                } else if zoomScaleStop == zoomScaleStops.last! {
                    scrollView.zoomScale = zoomScaleStops.first!
                }
            }
        }.startAnimation()
    }
    
    // Show options to visit the original webpage in an external browser,
    // or share this comic using the standard mechanism.
    @IBAction private func shareAction(_ sender: UIBarButtonItem) {
        guard let comic = comic else { return }
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let url = URL(string: "https://xkcd.com/\(comic.number)")!
        let image = imageView.image!
        
        actionSheet.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] (action) in
            let activityController = UIActivityViewController(activityItems: [comic.safeTitle, image, url], applicationActivities: nil)
            activityController.popoverPresentationController?.barButtonItem = sender
            self?.present(activityController, animated: true, completion: nil)
        })
        actionSheet.addAction(UIAlertAction(title: "Visit Website", style: .default) { (action) in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        actionSheet.popoverPresentationController?.barButtonItem = sender
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints()
    }
    
    // Update the constraints to keep the image centered in the scroll view.
    private func updateConstraints() {
        let xPadding = max(0, (containerSize.width - scaledImageSize.width) / 2)
        imageViewLeadingConstraint.constant = xPadding
        imageViewTrailingConstraint.constant = xPadding

        let yPadding = max(0, (containerSize.height - scaledImageSize.height) / 2)
        imageViewTopConstraint.constant = yPadding
        imageViewBottomConstraint.constant = yPadding

        view.layoutIfNeeded()
    }
}
