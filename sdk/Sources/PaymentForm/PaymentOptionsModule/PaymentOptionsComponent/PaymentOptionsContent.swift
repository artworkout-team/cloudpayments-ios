//
//  PaymentOptionsContent.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

protocol BottomSheetPaymentOptionsSelectionButtonDelegate: AnyObject {
    func didSelect(method: PaymentOptionsViewController.ResolvedPaymentMethod)
    func patch(email: String?, tokenize: Bool)
}

final class BottomSheetPaymentOptionsContentViewController: BaseViewController {
    
    //Button components
    private let configuration: PaymentConfiguration
    private var paymentButtons: [UIButton] = []
    private let methods: [PaymentOptionsViewController.ResolvedPaymentMethod]
    
    private var displayedResolvedMethods: [PaymentOptionsViewController.ResolvedPaymentMethod] = []
    private var additionalResolvedMethods: [PaymentOptionsViewController.ResolvedPaymentMethod] = []
    private var resolvedByButtonTag: [Int: PaymentOptionsViewController.ResolvedPaymentMethod] = [:]
    
    private(set) var additionalMethods: [PaymentMethodType] = []
    private(set) var displayedMethods: [PaymentMethodType] = []
    private(set) var showAdditional = false
    private var emailFillEventSent = false
    private let additionalButtonID = "additionalButton"
    private var moreButton: UIView?
    var onContentChanged: (() -> Void)?
    
    //Save card components
    private var saveCardContainer: UIView?
    private(set) var saveCardSwitch: UISwitch?
    private var saveCardTooltip: TooltipView?
    private let saveCardState: IntentSaveCardState?
    private let tokenize: Bool?
    
    // Email components
    private var emailContainer: ReceiptEmailView?
    private(set) var receiptSwitch: UISwitch?
    private let emailBehavior: EmailBehaviorType
    private let email: String?
    
    weak var delegate: BottomSheetPaymentOptionsSelectionButtonDelegate?
    
    init(
        methods: [PaymentOptionsViewController.ResolvedPaymentMethod],
        saveCardState: IntentSaveCardState?,
        tokenize: Bool?,
        emailBehavior: EmailBehaviorType,
        email: String?,
        configuration: PaymentConfiguration
    ) {
        self.configuration = configuration
        self.methods = methods
        self.saveCardState = saveCardState
        self.tokenize = tokenize
        self.emailBehavior = emailBehavior
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    
    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Выберите способ оплаты"
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let buttonsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        configureButtonsSaveCardAndEmailBlocks()
        view.layoutIfNeeded()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOutside))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreFromConfiguration()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollForKeyboard()
    }
    
    private func updateScrollForKeyboard() {
        guard let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else { return }
        
        let keyboardHeight = isKeyboardShowing ? keyboardFrame.height : 0
        
        UIView.animate(withDuration: 0.25) {
            scrollView.contentInset.bottom = keyboardHeight + 16
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc private func didTapOutside() {
        view.endEditing(true)
    }
    
    private func setupLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        contentView.addSubview(handleView)
        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            handleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 136),
            handleView.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, buttonsStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        let logoView = CloudPaymentsLogoView()
        logoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(logoView)
        
        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),
            logoView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func indexBeforeFirstNonButton() -> Int {
        if let index = buttonsStack.arrangedSubviews.firstIndex(where: { view in
            !(view is UIButton) && view.accessibilityIdentifier != additionalButtonID
        }) {
            return index
        } else {
            return buttonsStack.arrangedSubviews.count
        }
    }
    
    private func restoreCustomSpacings() {
        if let moreOrLast = moreButton ?? buttonsStack.arrangedSubviews.last {
            buttonsStack.setCustomSpacing(32, after: moreOrLast)
        }
        
        if let saveCardContainer {
            buttonsStack.setCustomSpacing(16, after: saveCardContainer)
        }
    }
    
    private func configureButtonsSaveCardAndEmailBlocks() {
        displayedMethods.removeAll()
        additionalMethods.removeAll()
        displayedResolvedMethods.removeAll()
        additionalResolvedMethods.removeAll()
        
        if methods.count <= 3 {
            for resolved in methods {
                let button = makeButton(for: resolved)
                buttonsStack.addArrangedSubview(button)
                
                displayedResolvedMethods.append(resolved)
                displayedMethods.append(resolved.displayType)
            }
        } else {
            for (index, resolved) in methods.enumerated() {
                if index < 2 {
                    let button = makeButton(for: resolved)
                    buttonsStack.addArrangedSubview(button)
                    
                    displayedResolvedMethods.append(resolved)
                    displayedMethods.append(resolved.displayType)
                } else {
                    additionalResolvedMethods.append(resolved)
                    additionalMethods.append(resolved.displayType)
                }
            }
            
            let more = makeMoreMethodsView(for: additionalResolvedMethods)
            buttonsStack.addArrangedSubview(more)
            moreButton = more
        }
        
        if let saveCardState {
            setupSaveCardUI(state: saveCardState, isSelected: tokenize ?? false)
        }
        
        let receiptSwitchView = makeReceiptSwitchAndEmailView()
        buttonsStack.addArrangedSubview(receiptSwitchView)
        restoreCustomSpacings()
    }
    
    private func makeButton(for resolved: PaymentOptionsViewController.ResolvedPaymentMethod) -> UIButton {
        let type = resolved.displayType
        
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        config.title = type.buttonTitle
        config.image = type.buttonIcon
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.baseBackgroundColor = type.backgroundColor
        
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        
        if type == .foreignCard {
            button.contentHorizontalAlignment = .center
            button.semanticContentAttribute = .forceRightToLeft
        }
        
        if type == .foreignCard {
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor(red: 46, green: 113, blue: 252, alpha: 1).cgColor,
                UIColor(red: 93, green: 23, blue: 196, alpha: 1).cgColor
            ]
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradient.frame = CGRect(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width - 32,
                height: 56
            )
            gradient.cornerRadius = 8
            button.layer.insertSublayer(gradient, at: 0)
        }
        
        let tag = resolvedByButtonTag.count + 1
        button.tag = tag
        resolvedByButtonTag[tag] = resolved
        
        button.addTarget(self, action: #selector(paymentButtonTapped(_:)), for: .touchUpInside)
        paymentButtons.append(button)
        
        print("Создали кнопку: type = \(type.rawValue), kind = \(resolved.kind), tag = \(tag)")
        
        return button
    }
    
    private func makeIconsStack(for methods: [PaymentOptionsViewController.ResolvedPaymentMethod]) -> UIView {
        let container = UIView()
        
        var previousView: UIImageView?
        
        for resolved in methods {
            let type = resolved.displayType
            
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = type.additionalButtonIcon
            imageView.contentMode = .scaleAspectFill
            imageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            container.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            
            if let prev = previousView {
                imageView.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: -8).isActive = true
            } else {
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            }
            
            if let prev = previousView {
                container.insertSubview(imageView, belowSubview: prev)
            }
            
            previousView = imageView
        }
        
        if let last = previousView {
            last.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        }
        
        return container
    }
    
    private func makeMoreMethodsView(for methods: [PaymentOptionsViewController.ResolvedPaymentMethod]) -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.colorBlue.cgColor
        view.heightAnchor.constraint(equalToConstant: 56).isActive = true
        view.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleAdditional))
        view.addGestureRecognizer(tap)
        
        let label = UILabel()
        label.text = "Другие способы"
        label.textColor = .colorBlue
        label.font = .systemFont(ofSize: 17)
        
        let iconsStack = makeIconsStack(for: methods)
        
        let container = UIStackView(arrangedSubviews: [label, iconsStack])
        container.axis = .horizontal
        container.spacing = 16
        container.alignment = .center
        container.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
    private func makeCollapseButton() -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = "Свернуть"
        config.baseForegroundColor = .systemBlue
        config.background.backgroundColor = .clear
        
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(toggleAdditional), for: .touchUpInside)
        return button
    }
    
    @objc private func toggleAdditional() {
        showAdditional.toggle()
        
        UIView.performWithoutAnimation {
            if showAdditional {
                if let more = moreButton {
                    buttonsStack.removeArrangedSubview(more)
                    more.removeFromSuperview()
                }
                
                for resolved in additionalResolvedMethods {
                    let button = makeButton(for: resolved)
                    button.accessibilityIdentifier = additionalButtonID
                    let insertIndex = indexBeforeFirstNonButton()
                    buttonsStack.insertArrangedSubview(button, at: insertIndex)
                }
                
                let collapse = makeCollapseButton()
                let insertIndex = indexBeforeFirstNonButton()
                buttonsStack.insertArrangedSubview(collapse, at: insertIndex)
                moreButton = collapse
            } else {
                if let collapse = moreButton {
                    buttonsStack.removeArrangedSubview(collapse)
                    collapse.removeFromSuperview()
                }
                
                for sub in buttonsStack.arrangedSubviews where sub.accessibilityIdentifier == additionalButtonID {
                    buttonsStack.removeArrangedSubview(sub)
                    sub.removeFromSuperview()
                }
                
                let more = makeMoreMethodsView(for: additionalResolvedMethods)
                let insertIndex = indexBeforeFirstNonButton()
                buttonsStack.insertArrangedSubview(more, at: insertIndex)
                moreButton = more
            }
            
            restoreCustomSpacings()
            view.layoutIfNeeded()
        }
        
        onContentChanged?()
        
        if !isKeyboardShowing {
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func makeReceiptSwitchAndEmailView() -> UIStackView {
        let label = UILabel()
        label.text = "Отправить квитанцию на E-mail"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        
        let toggle = UISwitch()
        toggle.onTintColor = .colorBlue
        
        let emailView = ReceiptEmailView()
        emailView.translatesAutoresizingMaskIntoConstraints = false
        emailView.emailBehavior = emailBehavior
        emailView.email = email
        emailView.isReceiptSwitchOn = { [weak toggle] in
            toggle?.isOn ?? false
        }
        emailView.setButtonsEnabled = { [weak self] enabled in
            self?.updateButtonsEnabled(enabled)
        }
        
        self.emailContainer = emailView
        self.receiptSwitch = toggle
        
        let toggleRow = UIStackView(arrangedSubviews: [label, UIView(), toggle])
        toggleRow.axis = .horizontal
        toggleRow.alignment = .center
        
        let stack = UIStackView(arrangedSubviews: [toggleRow])
        stack.axis = .vertical
        stack.spacing = 8
        
        switch emailBehavior {
        case .required:
            toggle.isHidden = true
            stack.addArrangedSubview(emailView)
            emailView.validateEmail(email)
        case .optional:
            if let email, !email.isEmpty {
                toggle.isOn = true
                stack.addArrangedSubview(emailView)
                emailView.validateEmail(email)
            }
        case .hidden:
            toggleRow.isHidden = true
        }
        toggle.addTarget(self, action: #selector(receiptSwitchChanged(_:)), for: .valueChanged)
        return stack
    }
    
    @objc private func receiptSwitchChanged(_ sender: UISwitch) {
        let context = sender.isOn ? "On" : "Off"
        
        AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "SendEmail", elementType: "Checkbox", actionType: "Click", screenName: "/methods", actionContext: context)
        
        guard let emailView = emailContainer,
              let stack = sender.superview?.superview as? UIStackView else { return }
        
        if sender.isOn {
            if !stack.arrangedSubviews.contains(emailView) {
                stack.addArrangedSubview(emailView)
            }
            emailView.validateEmail(emailView.email)
        } else {
            stack.removeArrangedSubview(emailView)
            emailView.removeFromSuperview()
            updateButtonsEnabled(true)
        }
        
        onContentChanged?()
        if !isKeyboardShowing {
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func setupSaveCardUI(state: IntentSaveCardState, isSelected: Bool) {
        saveCardContainer?.removeFromSuperview()
        saveCardTooltip?.removeFromSuperview()
        
        switch state {
        case .optional:
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Сохранить данные карты или счёта"
            label.font = .systemFont(ofSize: 15)
            label.textColor = .label
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            
            let infoButton = UIButton(type: .custom)
            infoButton.translatesAutoresizingMaskIntoConstraints = false
            infoButton.setImage(.icn_attention, for: .normal)
            infoButton.addTarget(self, action: #selector(showTooltip), for: .touchUpInside)
            
            let toggle = UISwitch()
            toggle.translatesAutoresizingMaskIntoConstraints = false
            toggle.isOn = isSelected
            toggle.onTintColor = .colorBlue
            saveCardSwitch = toggle
            
            container.addSubview(label)
            container.addSubview(infoButton)
            container.addSubview(toggle)
            
            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(equalToConstant: 31),
                
                toggle.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                toggle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                
                infoButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 4),
                infoButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                infoButton.widthAnchor.constraint(equalToConstant: 24),
                infoButton.heightAnchor.constraint(equalToConstant: 24),
                
                infoButton.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8)
            ])
            
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            infoButton.setContentCompressionResistancePriority(.required, for: .horizontal)
            infoButton.setContentHuggingPriority(.required, for: .horizontal)
            
            toggle.setContentCompressionResistancePriority(.required, for: .horizontal)
            toggle.setContentHuggingPriority(.required, for: .horizontal)
            
            buttonsStack.addArrangedSubview(container)
            saveCardContainer = container
            
        case .force:
            let container = UIStackView()
            container.axis = .horizontal
            container.spacing = 8
            container.alignment = .center
            container.distribution = .fill
            
            let label = UILabel()
            label.text = "При оплате данные карты сохранятся"
            label.font = .systemFont(ofSize: 15)
            label.textColor = .label
            
            let infoButton = UIButton(type: .system)
            infoButton.setImage(.icn_attention, for: .normal)
            infoButton.addTarget(self, action: #selector(showTooltip), for: .touchUpInside)
            
            container.addArrangedSubview(label)
            container.addArrangedSubview(UIView())
            container.addArrangedSubview(infoButton)
            
            buttonsStack.addArrangedSubview(container)
            saveCardContainer = container
            
        case .classic, .new:
            break
        }
    }
    
    @objc private func showTooltip() {
        if let tooltip = saveCardTooltip {
            tooltip.removeFromSuperview()
            saveCardTooltip = nil
            return
        }
        
        let tooltip = TooltipView(texts: [
            "После оплаты карта сохранится.\nВ следующий раз вам не понадобится \nвводить данные карты.",
            "Это удобно и экономит время."
        ])
        
        view.addSubview(tooltip)
        tooltip.translatesAutoresizingMaskIntoConstraints = false
        
        guard let container = saveCardContainer else {
            return
        }
        
        view.layoutIfNeeded()
        
        let containerFrame = container.convert(container.bounds, to: view)
        
        NSLayoutConstraint.activate([
            tooltip.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: containerFrame.minX),
            tooltip.widthAnchor.constraint(equalToConstant: containerFrame.width),
            tooltip.bottomAnchor.constraint(equalTo: view.topAnchor, constant: containerFrame.minY - 16)
        ])
        
        saveCardTooltip = tooltip
    }
    
    private func updateButtonsEnabled(_ enabled: Bool) {
        for view in buttonsStack.arrangedSubviews {
            if let button = view as? UIButton {
                button.isUserInteractionEnabled = enabled
                button.alpha = enabled ? 1.0 : 0.3
            } else if view.accessibilityIdentifier == additionalButtonID {
                view.isUserInteractionEnabled = enabled
                view.alpha = enabled ? 1.0 : 0.3
            }
            
            if let stack = view as? UIStackView {
                for subview in stack.arrangedSubviews {
                    if let toggle = subview as? UISwitch,
                       stack != saveCardContainer {
                        toggle.isEnabled = enabled
                    }
                }
            }
        }
        
        moreButton?.isUserInteractionEnabled = enabled
        moreButton?.alpha = enabled ? 1.0 : 0.3
    }
    
    @objc private func paymentButtonTapped(_ sender: UIButton) {
        guard let resolved = resolvedByButtonTag[sender.tag] else {
            return
        }
        
        let methodType = resolved.displayType
        
        print("Нажата кнопка: \(methodType.rawValue)")
        
        sender.startLoading(loaderImage: .ic_button_logo)
        
        if !emailFillEventSent, let emailView = emailContainer, let email = emailView.email, emailView.isEmailValid() {
            
            AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "Email", elementType: "Input", actionType: "Fill", screenName: "/methods", methodChosen: methodType.rawValue, actionContext: email)
            
            emailFillEventSent = true
        }
        
        delegate?.didSelect(method: resolved)
        
        let currentEmail = emailContainer?.email
        let tokenize = saveCardSwitch?.isOn ?? false
        
        delegate?.patch(email: currentEmail, tokenize: tokenize)
        
        sender.stopLoading(
            title: methodType.buttonTitle,
            icon: methodType.buttonIcon,
            backgroundColor: methodType.backgroundColor ?? .white
        )
    }
}

private extension BottomSheetPaymentOptionsContentViewController {
    func restoreFromConfiguration() {
        let paymentData = configuration.paymentData
        if paymentData.isAdditionalMethodsExpanded == true && !showAdditional {
            toggleAdditional()
        }
        if let saveCard = paymentData.isSaveCardSelected {
            saveCardSwitch?.isOn = saveCard
        }
        if let receipt = paymentData.isReceiptSelected {
            receiptSwitch?.isOn = receipt
            if let toggle = receiptSwitch {
                receiptSwitchChanged(toggle)
            }
        }
    }
}
