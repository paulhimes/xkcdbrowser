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
    
    @IBOutlet weak var moreDetailsView: UIView!
    @IBOutlet weak var alternateTextLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!
    
    @IBOutlet var zoomDoubleTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var toggleTapGestureRecognizer: UITapGestureRecognizer!
    
    private let margin: CGFloat = 8
    
    private var containerSize: CGSize {
        let containerWidth = view.bounds.size.width - view.safeAreaInsets.left - view.safeAreaInsets.right
        let containerHeight = view.bounds.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        return CGSize(width: containerWidth, height: containerHeight)
    }
    
    private var scaledImageSize: CGSize {
        guard let imageSize = imageView.image?.size else {
            return .zero
        }
        return CGSize(width: imageSize.width * scrollView.zoomScale, height: imageSize.height * scrollView.zoomScale)
    }
    
    var detailItem: ManagedComic? {
        didSet {
            configureView()
        }
    }
    
    func configureView() {
        guard let comic = detailItem else { return }
        title = comic.safeTitle
        
        alternateTextLabel?.text = comic.alternateText
        linkButton?.isHidden = comic.link == nil
        
        URLSession.shared.dataTask(with: comic.image) { [weak self] (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                if let imageView = self?.imageView {
                    imageView.image = image
                    self?.updateZoomScales()
                }
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

        let widthScale = (containerSize.width - margin * 2) / image.size.width
        let heightScale = (containerSize.height - margin * 2) / image.size.height
        let minScale = min(widthScale, heightScale)
        
        let maxScale = max(widthScale, heightScale)
        
        scrollView.minimumZoomScale = min(1, minScale)
        scrollView.maximumZoomScale = maxScale
        scrollView.zoomScale = scrollView.minimumZoomScale
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        toggleTapGestureRecognizer.require(toFail: zoomDoubleTapGestureRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateZoomScales()
        updateConstraints()
    }

    @IBAction func linkAction(_ sender: Any) {
        guard let link = detailItem?.link else { return }
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
    
    @IBAction func toggleAction(_ sender: Any) {
        UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            guard let moreDetailsView = self?.moreDetailsView else { return }
            moreDetailsView.alpha = moreDetailsView.alpha < 1 ? 1 : 0
        }.startAnimation()
    }
    
    @IBAction func zoomAction(_ sender: Any) {
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
    
    @IBAction func shareAction(_ sender: Any) {
        guard let comic = detailItem else { return }
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let url = URL(string: "https://xkcd.com/\(comic.number)")!
        let image = imageView.image!
        
        actionSheet.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] (action) in
            let activityController = UIActivityViewController(activityItems: [comic.safeTitle, image, url], applicationActivities: nil)
            self?.present(activityController, animated: true, completion: nil)
        })
        actionSheet.addAction(UIAlertAction(title: "Visit Website", style: .default) { (action) in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints()
    }
    
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
