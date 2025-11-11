//
//  NewSbpViewController.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 02.05.2024.
//

import UIKit
import SafariServices

final class ProgressSbpViewController: BaseViewController {
    
    // MARK: - Private Properties
    private let presenter: ProgressSbpPresenter
    private var contentView: ProgressSbpView = ProgressSbpView()
    private let loaderView = LoaderView()
    private var closedConstraint: NSLayoutConstraint!
    private var tableViewHeightConstraint: NSLayoutConstraint!
    
    private lazy var currentContainerHeight: CGFloat = contentView.bounds.height
    private var isClosed = false
    private let useDimming: Bool
    private var heightPresentView: CGFloat { return contentView.bounds.height }
    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
    
    override var isKeyboardShowing: Bool {
        didSet {
            tapGestureRecognizer.cancelsTouchesInView = isKeyboardShowing
        }
    }
    
    // MARK: - Init
    init(presenter: ProgressSbpPresenter, useDimming: Bool = true) {
        self.presenter = presenter
        self.useDimming = useDimming
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Present
    class func present(with configuration: PaymentConfiguration, from: UIViewController) {
        let presenter = ProgressSbpPresenter(configuration: configuration)
        let controller = ProgressSbpViewController(presenter: presenter)
        presenter.view = controller
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        controller.view.isOpaque = false
        from.present(controller, animated: false)
    }
    
    // MARK: - LifeCycle
    override func loadView() {
        super.loadView()
        setupConstraintsAndView()
        
        loaderView.frame = view.bounds
        loaderView.fullConstraint()
        loaderView.layoutSubviews()
        loaderView.startAnimated(LoaderType.loadingBanks.toString())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.delegate = self
        view.backgroundColor = .init(red: 1, green: 1, blue: 1, alpha: 0.0)
        presenter.getBanks()
        addGesture()
        
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationView(true) {}
        LoggerService.shared.startLogging(publicId: presenter.configuration.publicId)
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: presenter.configuration, screenName: "/methods", methodChosen: "Sbp", cardFieldsCount: 0, eventType: "Open")
    }
    
    deinit {
        presenter.stopPolling()
    }
    
    private func showWaitScreen() {
        let progressView = ProgressPaymentView(method: .sbp)
        progressView.delegate = self
        progressView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        if useDimming {
            self.view.backgroundColor = .clear
        }
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: presenter.configuration, screenName: "Waiting", methodChosen: "Sbp", cardFieldsCount: 0, eventType: "Open")
    }
    
    // MARK: - Private methods
    private func setupConstraintsAndView() {
        view.addSubviews(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        closedConstraint = contentView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        closedConstraint.isActive = true
        
        let contentBottomConstraint = contentView.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor)
        contentBottomConstraint.priority = .init(900)
        contentBottomConstraint.isActive = true
    }
    
    @objc private func tapAction() {
        view.endEditing(true)
    }
    
    private func addGesture() {
        let panGesture = UIPanGestureRecognizer()
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        contentView.addGestureRecognizer(panGesture)
    }
    
    // MARK: Pan gesture handler
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let y = gesture.translation(in: view).y
        let newHeight = currentContainerHeight - y
        let procent = 30.0
        let defaultHeight = heightPresentView - ((heightPresentView * procent) / 100)
        
        switch gesture.state {
        case .changed:
            if heightPresentView < newHeight {
                closedConstraint.constant = -heightPresentView
                currentContainerHeight = heightPresentView
                view.layoutIfNeeded()
                return
            }
            
            closedConstraint.constant = -newHeight
            view.layoutIfNeeded()
            
        case .ended, .cancelled:
            if newHeight < defaultHeight {
                currentContainerHeight = newHeight
                guard let parent = self.presentingViewController else { return }
                let configuration = self.presenter.configuration
                presentationView(false) {
                    self.dismiss(animated: false) {
                        configuration.paymentDelegate.paymentClosed()
                        if !configuration.paymentData.singlePaymentMethod {
                            PaymentOptionsViewController.present(
                                with: configuration,
                                from: parent,
                                skipLoader: true
                            )
                        }
                        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods", methodChosen: "Sbp", cardFieldsCount: 0, eventType: "Close")
                        AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
                    }
                }
            } else {
                closedConstraint.constant = -heightPresentView
                currentContainerHeight = heightPresentView
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
                    self.view.layoutIfNeeded()
                }
            }
        default:
            break
        }
    }
    
    private func presentationView(_ isPresent: Bool, completion: @escaping () -> Void) {
        if isClosed { return }
        isClosed = !isPresent
        currentContainerHeight = heightPresentView
        
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
            self.closedConstraint.constant = isPresent ? -self.heightPresentView : 0
            
            if self.useDimming {
                let alpha = isPresent ? 0.5 : 0
                self.view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            } else {
                self.view.backgroundColor = .clear
            }
            
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion()
        }
    }
}

// MARK: - CustomSbpViewDelegate
extension ProgressSbpViewController: CustomSbpViewDelegate {
    func numberOfRow(_ progressSbpView: ProgressSbpView, didChange text: String) {
        let trimmedSearchText = text.trimmingCharacters(in: .whitespaces)
        presenter.editingSearchBar(trimmedSearchText)
    }
    
    func searchBarCancelButtonClicked(_ progressSbpView: ProgressSbpView) {
        presenter.editingSearchBar("")
    }
    
    func numberOfRow(_ progressSbpView: ProgressSbpView) -> Int {
        return presenter.filteredBanks.count
    }
    
    func progressSbpView(_ progressSbpView: ProgressSbpView, didSelect row: Int) {
        presenter.stopPolling()
        presenter.didSelectRow(row)
        contentView.removeFromSuperview()
        showWaitScreen()
    }
    
    func progressSbpView(_ progressSbpView: ProgressSbpView, cellFor row: Int) -> Bank {
        return presenter.filteredBanks[row]
    }
}

// MARK: - ProgressPaymentViewDelegate
extension ProgressSbpViewController: ProgressPaymentViewDelegate {
    func closePaymentButton() {
        resultPayment(result: .close, error: nil, transaction: nil)
    }
}

// MARK: - ProgressSbpViewControllerProtocol
extension ProgressSbpViewController: ProgressSbpViewControllerProtocol {
    func showAlert(message: String?, title: String?) {
        showAlert(title: title, message: message) { [weak self] in
            guard let self, let parent = self.presentingViewController else { return }
            self.dismiss(animated: false) {
                PaymentOptionsViewController.present(
                    with: self.presenter.configuration,
                    from: parent,
                    skipLoader: true
                )
                AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: self.presenter.configuration)
            }
        }
    }
    
    func presentError(_ error: String? = nil) {
        resultPayment(result: .error, error: error, transaction: nil)
    }
    
    func openSafariViewController(_ url: URL) {
        let safariViewController = SafariViewController(url: url)
        safariViewController.delegate = self
        
        if let top = UIApplication.topViewController() {
            top.present(safariViewController, animated: true)
        }
    }
    
    func openBanksApp(_ url: URL) {
        UIApplication.shared.open(url) { success in
            if success {
                self.presenter.startPolling()
            } else {
                self.showAlert(title: nil, message: .noBankApps)
            }
        }
    }
    
    func resultPayment(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?
    ) {
        let configuration = presenter.configuration
        guard let parent = presentingViewController else { return }
        
        /// showResultScreen = true, singlePaymentMethod = true
        if configuration.paymentData.singlePaymentMethod {
            if configuration.showResultScreen {
                handleSingleMethodResultScreen(result: result,
                                               error: error,
                                               transaction: transaction,
                                               configuration: configuration,
                                               parent: parent)
            } else {
                /// showResultScreen = false, singlePaymentMethod = true
                handleSingleMethodNoResultScreen(result: result,
                                                 error: error,
                                                 transaction: transaction,
                                                 configuration: configuration)
            }
        } else {
            /// showResultScreen = false, singlePaymentMethod = false
            handleStandartMethodResultScreen(result: result,
                                            error: error,
                                            transaction: transaction,
                                            configuration: configuration,
                                            parent: parent)
        }
    }
    
    func tableViewReloadData() {
        contentView.reloadData()
    }
}

// MARK: - Result handling
private extension ProgressSbpViewController {
    func handleSingleMethodResultScreen(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?,
        configuration: PaymentConfiguration,
        parent: UIViewController
    ) {
        presentationView(false) {
            self.dismiss(animated: false) {
                switch result {
                case .success:
                    let amountText = "\(configuration.paymentData.amount) \(Currency.getCurrencySign(code: configuration.paymentData.currency))"
                    PaymentResultViewController.present(from: parent, state: .completed(amountText: amountText, transaction: transaction), orderAlreadyBeenPaid: error) {
                        configuration.paymentDelegate.paymentFinished(transaction)
                        configuration.paymentDelegate.paymentClosed()
                        AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ReturnToShop", elementType: "Button", actionType: "Click", screenName: "/success")
                    }
                    AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/success", methodChosen: "Sbp", cardFieldsCount: 0, eventType: "Open")
                case .error:
                    PaymentResultViewController.present(from: parent, state: .declined(message: error)) {
                        configuration.paymentDelegate.paymentFailed(error)
                        AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "Try again", elementType: "Button", actionType: "Click", screenName: "/fail")
                    }
                    AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/fail", methodChosen: "Sbp", cardFieldsCount: 0, eventType: "Open", errorContext: transaction?.code)
                case .close:
                    configuration.paymentDelegate.paymentClosed()
                }
            }
        }
    }
    
    func handleSingleMethodNoResultScreen(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?,
        configuration: PaymentConfiguration
    ) {
        presentationView(false) {
            self.dismiss(animated: true) {
                switch result {
                case .success:
                    configuration.paymentDelegate.paymentFinished(transaction)
                case .error:
                    configuration.paymentDelegate.paymentFailed(error)
                case .close:
                    configuration.paymentDelegate.paymentClosed()
                }
            }
        }
    }
    
    func handleStandartMethodResultScreen(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?,
        configuration: PaymentConfiguration,
        parent: UIViewController
    ) {
        presentationView(false) {
            self.dismissSafariIfNeeded { 
                self.dismiss(animated: false) {
                    switch result {
                    case .success:
                        let amountText = "\(configuration.paymentData.amount) \(Currency.getCurrencySign(code: configuration.paymentData.currency))"
                        PaymentResultViewController.present(from: parent, state: .completed(amountText: amountText, transaction: transaction), orderAlreadyBeenPaid: error) {
                            configuration.paymentDelegate.paymentFinished(transaction)
                            configuration.paymentDelegate.paymentClosed()
                            AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ReturnToShop", elementType: "Button", actionType: "Click", screenName: "/success")
                        }
                        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/success", methodChosen: "Sbp", cardFieldsCount: 0, eventType: "Open")
                        
                    case .error:
                        PaymentResultViewController.present(from: parent, state: .declined(message: error)) {
                            configuration.paymentDelegate.paymentFailed(error)
                            PaymentOptionsViewController.present(with: configuration, from: parent, skipLoader: true)
                            AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "Try again", elementType: "Button", actionType: "Click", screenName: "/fail")
                            AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
                        }
                        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/fail", methodChosen: "Sbp", cardFieldsCount: 0, eventType: "Open", errorContext: transaction?.code)
                    case .close:
                        configuration.paymentDelegate.paymentClosed()
                        PaymentOptionsViewController.present(with: configuration, from: parent, skipLoader: true)
                        AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ChooseOtherMethod", elementType: "Button", actionType: "Click", screenName: "/methods")
                        AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
                    }
                }
            }
        }
    }
}

// MARK: - SFSafariViewControllerDelegate
extension ProgressSbpViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        presenter.stopPolling()
        print("Safari закрыт, polling остановлен")
    }
    
    private func dismissSafariIfNeeded(completion: @escaping () -> Void) {
        if let safari = presentedViewController as? SFSafariViewController {
            safari.dismiss(animated: false, completion: completion)
        } else {
            completion()
        }
    }
}
