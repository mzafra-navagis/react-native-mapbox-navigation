import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

// // adapted from https://pspdfkit.com/blog/2017/native-view-controllers-and-react-native/ and https://github.com/mslabenyak/react-native-mapbox-navigation/blob/master/ios/Mapbox/MapboxNavigationView.swift
extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

class MapboxNavigationView: UIView, NavigationViewControllerDelegate {
    weak var navViewController: NavigationViewController?
    var embedded: Bool
    var embedding: Bool
    
    @objc var origin: NSArray = [] {
        didSet { setNeedsLayout() }
    }
    
    @objc var destination: NSArray = [] {
        didSet { setNeedsLayout() }
    }
    
    @objc var shouldSimulateRoute: Bool = false
    @objc var showsEndOfRouteFeedback: Bool = false
    @objc var hideStatusView: Bool = true
    @objc var mute: Bool = false
    
    @objc var onLocationChange: RCTDirectEventBlock?
    @objc var onRouteProgressChange: RCTDirectEventBlock?
    @objc var onError: RCTDirectEventBlock?
    @objc var onCancelNavigation: RCTDirectEventBlock?
    @objc var onArrive: RCTDirectEventBlock?
    
    override init(frame: CGRect) {
        self.embedded = false
        self.embedding = false
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (navViewController == nil && !embedding && !embedded) {
            embed()
        } else {
            navViewController?.view.frame = bounds
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        // cleanup and teardown any existing resources
        self.navViewController?.removeFromParent()
    }
    
    private func embed() {
        guard origin.count == 2 && destination.count == 2 else { return }
        
        embedding = true
        
        let originWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: origin[1] as! CLLocationDegrees, longitude: origin[0] as! CLLocationDegrees))
        let destinationWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destination[1] as! CLLocationDegrees, longitude: destination[0] as! CLLocationDegrees))
        
        // let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint])
        let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint], profileIdentifier: .automobileAvoidingTraffic)
        
        Directions.shared.calculate(options) { [weak self] (_, result) in
            guard let strongSelf = self, let parentVC = strongSelf.parentViewController else {
                return
            }
            
            print("embed")
            switch result {
            case .failure(let error):
                strongSelf.onError!(["message": error.localizedDescription])
            case .success(let response):
                guard let weakSelf = self else {
                    return
                }
                
                let navigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: options, simulating: strongSelf.shouldSimulateRoute ? .always : .never)
                
                let bottomBanner = CustomBottomBarViewController()
                let navigationOptions = NavigationOptions(navigationService: navigationService,
                                                          bottomBanner: bottomBanner)
                let vc = NavigationViewController(for: response, routeIndex: 0, routeOptions: options, navigationOptions: navigationOptions)
                
                bottomBanner.navigationViewController = vc
                
                vc.showsEndOfRouteFeedback = strongSelf.showsEndOfRouteFeedback
                StatusView.appearance().isHidden = strongSelf.hideStatusView
                
                NavigationSettings.shared.voiceMuted = strongSelf.mute;
                
                vc.delegate = strongSelf
                
                parentVC.addChild(vc)
                strongSelf.addSubview(vc.view)
                vc.view.frame = strongSelf.bounds
                vc.didMove(toParent: parentVC)
                strongSelf.navViewController = vc
                strongSelf.navViewController?.hidesBottomBarWhenPushed = true
            }
            
            strongSelf.embedding = false
            strongSelf.embedded = true
        }
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        onLocationChange?(["longitude": location.coordinate.longitude, "latitude": location.coordinate.latitude,
                           "progress": getRouteProgress(progress),
                           "location": getLocation(rawLocation)])
        onRouteProgressChange?(["isFinalLeg": progress.isFinalLeg,
                                  "legIndex": progress.legIndex,
                                  "distanceTraveled": progress.distanceTraveled,
                                  "durationRemaining": progress.durationRemaining,
                                  "fractionTraveled": progress.fractionTraveled,
                                  "distanceRemaining": progress.distanceRemaining,
                                  "currentLegProgress": getRouteLegProgress(progress.currentLegProgress)])
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        if (!canceled) {
            return;
        }
        onCancelNavigation?(["message": ""]);
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        navigationViewController.showsEndOfRouteFeedback = false
        onArrive?(["waypoint": getWaypoint(waypoint)]);
        return true;
    }
    
    
}


// MARK: - CustomBottomBarViewController

class CustomBottomBarViewController: ContainerViewController, CustomBottomBannerViewDelegate {
    
    weak var navigationViewController: NavigationViewController?
    
    // Or you can implement your own UI elements
    lazy var bannerView: CustomBottomBannerView = {
        let banner = CustomBottomBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.delegate = self
        return banner
    }()
    
    override func loadView() {
        super.loadView()
        
        view.addSubview(bannerView)
        
        let safeArea = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            bannerView.heightAnchor.constraint(equalTo: view.heightAnchor),
            bannerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupConstraints()
    }
    
    private func setupConstraints() {
        if let superview = view.superview?.superview {
            view.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
    }
    
    // MARK: - NavigationServiceDelegate implementation
    
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
    }
    
    // MARK: - CustomBottomBannerViewDelegate implementation
    
    func customBottomBannerDidCancel(_ banner: CustomBottomBannerView) {
        navigationViewController?.dismiss(animated: true,
                                          completion: nil)
    }
}
