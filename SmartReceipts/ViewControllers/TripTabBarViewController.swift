//
//  TripTabBarViewController.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 16.11.2019.
//  Copyright © 2019 Will Baumann. All rights reserved.
//

import UIKit
import RxSwift
import SafariServices

class TripTabBarViewController: TabBarViewController {
    private let bag = DisposeBag()
    private var trip: WBTrip!
    private var tooltipPresenter: TooltipPresenter!
    
    static func create(trip: WBTrip) -> TripTabBarViewController {
        let result = Self.create()
        result.trip = trip
        return result
    }
    
    override func viewDidLoad() {
        setupViewControllers()
        super.viewDidLoad()
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        switch item.tag {
        case Constants.unselectableTag: return
        case Constants.actionTag: showMore(); return
        default: break
        }
        
        super.tabBar(tabBar, didSelect: item)
    }
    
    // MARK: Private
    
    private func showMore() {
       presentMoreSheet()
    }
    
    private func setupViewControllers() {
        let receiptsModule = AppModules.receipts.build()
        let distancesModule = AppModules.tripDistances.build()
        let generateModule = AppModules.generateReport.build()
        
        receiptsModule.presenter.setupView(data: trip)
        distancesModule.presenter.setupView(data: trip)
        generateModule.presenter.setupView(data: trip)
        
        viewControllers = [
            receiptsModule.view.viewController.tabConfigured(image: #imageLiteral(resourceName: "receipts_tab"), selected: #imageLiteral(resourceName: "receipts_tab_selected")),
            distancesModule.view.viewController.tabConfigured(image: #imageLiteral(resourceName: "distances_tab"), selected: #imageLiteral(resourceName: "distances_tab_selected")),
            UIViewController().tabDisabled(),
            generateModule.view.viewController.tabConfigured(image: #imageLiteral(resourceName: "share_tab"), selected: #imageLiteral(resourceName: "share_tab_selected")),
            UIViewController().tabConfigured(image: #imageLiteral(resourceName: "more_tab"), selected: #imageLiteral(resourceName: "more_tab_selected"), tag: Constants.actionTag)
        ]
    }
}

private extension TripTabBarViewController {
    func presentMoreSheet() {
        let actionSheet = ActionSheet()
        
        actionSheet.addAction(title: LocalizedString("menu_main_settings"), image: #imageLiteral(resourceName: "settings"))
            .subscribe(onNext: { [weak self] in self?.openSettings() })
            .disposed(by: bag)
        
        actionSheet.addAction(title: LocalizedString("menu_main_ocr_configuration"), image: #imageLiteral(resourceName: "cpu"))
            .subscribe(onNext: { [weak self] in self?.openAutoScans() })
            .disposed(by: bag)
        
        actionSheet.addAction(title: LocalizedString("menu_main_export"), image: #imageLiteral(resourceName: "upload-cloud"))
            .subscribe(onNext: { [weak self] in self?.openBackup() })
            .disposed(by: bag)
        
        actionSheet.addAction(title: LocalizedString("menu_main_usage_guide"), image: #imageLiteral(resourceName: "info"))
            .subscribe(onNext: { [weak self] in self?.openUserGuide() })
            .disposed(by: bag)
        
        actionSheet.show()
    }
    
    func openAuth() -> AuthModuleInterface {
        let module = AppModules.auth.build()
        present(UINavigationController(rootViewController: module.view.viewController), animated: true, completion: nil)
        return module.interface(AuthModuleInterface.self)
    }
    
    func openAutoScans() {
        if AuthService.shared.isLoggedIn {
            AnalyticsManager.sharedManager.record(event: Event.Navigation.OcrConfiguration)
            let module = AppModules.OCRConfiguration.build()
            present(UINavigationController(rootViewController: module.view.viewController), animated: true, completion: nil)
        } else {
            let authModule = openAuth()
            authModule.successAuth
                .map({ authModule.close() })
                .delay(VIEW_CONTROLLER_TRANSITION_DELAY, scheduler: MainScheduler.instance)
                .flatMap({ _ -> Observable<UNAuthorizationStatus> in
                    PushNotificationService.shared.authorizationStatus()
                }).observeOn(MainScheduler.instance)
                .flatMap({ status -> Observable<Void> in
                    let text = LocalizedString("push_request_alert_text")
                    return status == .notDetermined ? UIAlertController.showInfo(text: text) : Observable<Void>.just(())
                }).subscribe(onNext: { [unowned self] in
                    _ = PushNotificationService.shared.requestAuthorization().subscribe()
                    self.openAutoScans()
                }).disposed(by: bag)
        }
    }
    
    func openSettings() {
        let module = AppModules.settings.build()
        present(UINavigationController(rootViewController: module.view.viewController), animated: true, completion: nil)
    }

    func openBackup() {
        let module = AppModules.backup.build()
        present(UINavigationController(rootViewController: module.view.viewController), animated: true, completion: nil)
    }
    
    func openUserGuide() {
        let USER_GUIDE_URL = "https://www.smartreceipts.co/guide"
        AnalyticsManager.sharedManager.record(event: Event.Navigation.OcrConfiguration)
        let safari = SFSafariViewController(url: URL(string: USER_GUIDE_URL)!, entersReaderIfAvailable: true)
        present(safari, animated: true, completion: nil)
    }
}

private extension UIViewController {
    func tabConfigured(image: UIImage, selected: UIImage? = nil, tag: Int = 0) -> UIViewController {
        tabBarItem = UITabBarItem(title: nil, image: image, tag: tag)
        tabBarItem.imageInsets = .init(top: UI_MARGIN_16, left: 0, bottom: -UI_MARGIN_16, right: 0)
        tabBarItem.selectedImage = selected
        return self
    }
    
    func tabDisabled() -> UIViewController {
        tabBarItem.isEnabled = false
        return self
    }
}

extension TripTabBarViewController {
    enum Constants {
        static let actionTag = -2
    }
}

typealias TitleSubtitle = (String, String?)