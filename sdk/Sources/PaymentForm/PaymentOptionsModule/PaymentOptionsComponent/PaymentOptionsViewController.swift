//
//  PaymentOptionsViewController.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

public final class PaymentOptionsViewController: BaseViewController {
    
    // MARK: - Life cycle
    
    private let loaderView = LoaderView()
    private let configuration: PaymentConfiguration
    private let viewModel: BottomSheetPaymentOptionsViewModel
    private let skipLoader: Bool
    private var isLoading = false
    
    init(configuration: PaymentConfiguration, skipLoader: Bool = false) {
        self.configuration = configuration
        self.skipLoader = skipLoader
        self.viewModel = BottomSheetPaymentOptionsViewModel(configuration: configuration)
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Present
    
    @discardableResult
    public class func present(with configuration: PaymentConfiguration, from presentingViewController: UIViewController, skipLoader: Bool = false, completion: (() -> ())? = nil) -> PaymentOptionsViewController {
        let controller = PaymentOptionsViewController(configuration: configuration, skipLoader: skipLoader)
        presentingViewController.present(controller, animated: true) {
            completion?()
        }
        if !configuration.paymentData.analyticsSessionStarted {
            AnalyticsService.shared.startSession()
            AnalyticsService.shared.sendScreenOpenedEvent(
                configuration: configuration,
                screenName: "PreStart",
                cardFieldsCount: 0,
                eventType: "Open"
            )
            configuration.paymentData.analyticsSessionStarted = true
        }
        return controller
    }
    
    public override func loadView() {
        super.loadView()
        if !skipLoader {
            view.addSubview(loaderView)
            loaderView.frame = view.bounds
            loaderView.fullConstraint()
            loaderView.isHidden = true
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if skipLoader,
           let methods = configuration.paymentData.cachedMethods, !methods.isEmpty {
            presentOptions(methods: methods, paymentMethodSequence: nil, intent: nil)
        } else {
            showLoading()
        }
        LoggerService.shared.startLogging(publicId: configuration.publicId)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if configuration.paymentData.singlePaymentMethod == false {
            configuration.paymentUIDelegate.paymentFormWillDisplay()
            configuration.paymentUIDelegate.paymentFormDidDisplay()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if configuration.paymentData.singlePaymentMethod == false {
            configuration.paymentUIDelegate.paymentFormWillHide()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if configuration.paymentData.singlePaymentMethod == false {
            configuration.paymentUIDelegate.paymentFormDidHide()
        }
    }
    
    // MARK: - Loader
    
    private func showLoading() {
        loaderView(isOn: true) {
            self.viewModel.loadPublicKeyAndCreateIntent { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let (methods, paymentMethodSequence, intent)):
                        self.loaderView(isOn: false) {
                            self.presentOptions(methods: methods, paymentMethodSequence: paymentMethodSequence, intent: intent)
                        }
                    case .failure(_):
                        self.loaderView(isOn: false) {
                            AnalyticsService.shared.sendScreenOpenedEvent(configuration: self.configuration, screenName: "/static-error", cardFieldsCount: 0, eventType: "Open")
                            self.showAlert(title: .errorWord, message: .errorConfiguration) {
                                self.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func presentOptions(methods: [PaymentMethod], paymentMethodSequence: [String]?, intent: PaymentIntentResponse?) {
        let sequence: [String]
        if let paymentMethodSequence, !paymentMethodSequence.isEmpty {
            sequence = paymentMethodSequence
        } else {
            sequence = configuration.paymentMethodSequence.map { $0.rawValue }
        }

        var prioritized: [PaymentMethod] = []
        for type in sequence {
            if let method = methods.first(where: { $0.type == type }) {
                prioritized.append(method)
            }
        }

        for method in methods where !sequence.contains(method.type ?? "") {
            prioritized.append(method)
        }
        
        let targetMethods = prioritized
        configuration.paymentData.singlePaymentMethod = sequence.count == 1
        
        if configuration.paymentData.singlePaymentMethod,
           configuration.showResultScreen,
           sequence.isEmpty {
            self.showAlert(title: .errorWord, message: .errorConfiguration) {
                self.dismiss(animated: true)
            }
            return
        }

        if targetMethods.count > 1 {
            showOptionsScreen(methods: targetMethods, intent: intent)
        } else if let single = targetMethods.first {
            let needOptions: Bool = {
                switch configuration.emailBehavior {
                case .required:
                    return configuration.paymentData.email.isNilOrEmpty
                case .optional, .hidden:
                    return false
                }
            }()

            if needOptions {
                showOptionsScreen(methods: targetMethods, intent: intent)
            } else {
                if configuration.paymentData.singlePaymentMethod {
                    if let type = PaymentMethodType(rawValue: single.type ?? "") {
                        switch type {
                        case .card:
                            launchDirectFlowCard(for: single)
                        case .sbp:
                            launchDirectFlowSbp(for: single)
                        default:
                            launchDirectFlowOtherMethods(for: single)
                        }
                    }
                } else {
                    showOptionsScreen(methods: targetMethods, intent: intent)
                }
            }
        }
    }
    
    private func showOptionsScreen(methods: [PaymentMethod], intent: PaymentIntentResponse?) {
        let viewModel = BottomSheetViewModel(cornerRadius: 20)
        let saveCardState = configuration.paymentData.intentSaveCardState
        let savedTokenize = configuration.paymentData.savedTokenize ?? false
        let emailBehavior = configuration.emailBehavior
        let email = configuration.paymentData.email
        let contentVC = BottomSheetPaymentOptionsContentViewController(
            methods: methods,
            saveCardState: saveCardState,
            tokenize: savedTokenize,
            emailBehavior: emailBehavior,
            email: email,
            configuration: configuration
        )
        contentVC.delegate = self
        contentVC.onContentChanged = { [weak self] in
            guard let self else { return }
            self.configuration.paymentData.isAdditionalMethodsExpanded = contentVC.showAdditional
            self.configuration.paymentData.isSaveCardSelected = contentVC.saveCardSwitch?.isOn
            self.configuration.paymentData.isReceiptSelected = contentVC.receiptSwitch?.isOn
        }
        let sheet = BottomSheetController(viewModel: viewModel, content: contentVC)
        sheet.present(in: self)
        
        if let intent = intent {
            let displayedMethods = contentVC.displayedMethods.map { $0.rawValue }
            let methodsAvailable = (contentVC.displayedMethods + contentVC.additionalMethods).map { $0.rawValue }
            configuration.paymentData.methodsAvailable = methodsAvailable
            
            AnalyticsService.shared.sendScreenOpenedEvent(configuration: self.configuration,
                                                          screenName: "Start",
                                                          methodsAvailable: methodsAvailable,
                                                          cardFieldsCount: 0,
                                                          eventType: "Open")
            AnalyticsService.shared.sendPaymentMethodsStartSessionEvent(
                configuration: configuration,
                intent: intent,
                methodsAvailable: methodsAvailable,
                displayedMethods: displayedMethods
            )
        }
        
        sheet.onDismiss = { [weak self] isSwipe in
            guard let self else { return }
            if isSwipe {
                AnalyticsService.shared.sendActionClickEvent(
                    configuration: configuration,
                    elementLabel: "Close",
                    elementType: "Modal",
                    actionType: "Close",
                    screenName: "/methods"
                )
            }
        }
    }
    
    private func launchDirectFlowCard(for method: PaymentMethod) {
        guard let type = PaymentMethodType(rawValue: method.type ?? "") else { return }
        guard type == .card else { return }
        let nextVC = PaymentCardViewController(configuration: configuration, useDimming: false)
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        addChild(nextVC)
        nextVC.view.frame = view.bounds
        nextVC.view.alpha = 0
        view.addSubview(nextVC.view)
        
        UIView.animate(withDuration: 0.35, animations: {
            nextVC.view.alpha = 1
        })
        
        nextVC.didMove(toParent: self)
    }
    
    private func launchDirectFlowOtherMethods(for method: PaymentMethod) {
        guard let type = PaymentMethodType(rawValue: method.type ?? "") else { return }
        guard let controller = self.presentingViewController else { return }
        
        self.dismiss(animated: false) {
            switch type {
            case .tpay:
                ProgressTPayViewController.present(with: self.configuration, from: controller)
            case .sberPay:
                ProgressSberPayViewController.present(with: self.configuration, from: controller)
            case .dolyame:
                ProgressDolyameViewController.present(with: self.configuration, from: controller)
            default: break
            }
        }
    }
    
    private func launchDirectFlowSbp(for method: PaymentMethod) {
        guard let type = PaymentMethodType(rawValue: method.type ?? "") else { return }
        guard type == .sbp else { return }

        let presenter = ProgressSbpPresenter(configuration: configuration)
        let nextVC = ProgressSbpViewController(presenter: presenter, useDimming: false)
        presenter.view = nextVC

        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        addChild(nextVC)
        nextVC.view.frame = view.bounds
        nextVC.view.alpha = 0
        view.addSubview(nextVC.view)
        
        UIView.animate(withDuration: 0.35, animations: {
            nextVC.view.alpha = 1
        })
        
        nextVC.didMove(toParent: self)
    }
}

private extension PaymentOptionsViewController {
    func loaderView(isOn: Bool, completion: @escaping () -> Void) {
        if isOn {
            self.loaderView.isHidden = false
            self.loaderView.startAnimated()
        } else {
            self.loaderView.endAnimated()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.loaderView.alpha = isOn ? 1 : 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.loaderView.isHidden = !isOn
            completion()
        }
    }
}

extension PaymentOptionsViewController: BottomSheetPaymentOptionsSelectionButtonDelegate {
    func didSelect(method: PaymentMethodType) {
        if let sheet = self.children.first(where: { $0 is BottomSheetController }) as? BottomSheetController,
           let content = sheet.children.first(where: { $0 is BottomSheetPaymentOptionsContentViewController })
            as? BottomSheetPaymentOptionsContentViewController {
            self.configuration.paymentData.isAdditionalMethodsExpanded = content.showAdditional
            self.configuration.paymentData.isSaveCardSelected = content.saveCardSwitch?.isOn
            self.configuration.paymentData.isReceiptSelected = content.receiptSwitch?.isOn
        }
        
        AnalyticsService.shared.sendActionClickEvent(
            configuration: configuration,
            elementLabel: method.rawValue,
            elementType: "Button",
            actionType: "Click",
            screenName: "/methods"
        )
        
        guard let present = method.presentViewController else { return }
        self.dismiss(animated: false) { [weak self] in
            guard let self = self,
                  let topController = UIApplication.topViewController() else { return }
            present(topController, self.configuration)
        }
    }
    
    func patch(email: String?, tokenize: Bool) {
        let patch = PatchBuilder.make { builder in
            if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines),
               !email.isEmpty,
               email.emailIsValid() {
                builder.replace("/receiptEmail", value: email)
                configuration.paymentData.email = email
            } else {
                configuration.paymentData.email = nil
            }
            
            if case .optional = configuration.paymentData.intentSaveCardState {
                builder.replace("/tokenize", value: tokenize)
                configuration.paymentData.savedTokenize = tokenize
            }
        }
        
        guard !patch.isEmpty else {
            return
        }
        
        CloudpaymentsApi.intentPatchById(configuration: configuration, patches: patch) { result in
            print("PATCH выполнен. Email: \(String(describing: result?.receiptEmail)), Tokenize: \(tokenize)")
        }
    }
}
