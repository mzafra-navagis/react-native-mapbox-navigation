//
//  CustomBottomBannerView.swift
//  react-native-mapbox-navigation
//
//  Created by Michael Angelo Zafra on 12/6/23.
//

import UIKit
import MapboxNavigation

protocol CustomBottomBannerViewDelegate: AnyObject {
    func customBottomBannerDidCancel(_ banner: CustomBottomBannerView)
}

class CustomBottomBannerView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    
    weak var delegate: CustomBottomBannerViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        delegate?.customBottomBannerDidCancel(self)
    }
}
