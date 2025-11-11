//
//  PaymentResultViewController.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import WebKit

protocol PaymentResultViewControllerDelegate: AnyObject {
    func paymentResultPrimaryTapped(state: PaymentResultViewController.State)
}

final class PaymentResultViewController: UIViewController {
    
    // MARK: Public
    weak var delegate: PaymentResultViewControllerDelegate?
    private let state: State
    private let orderAlreadyBeenPaid: String?
    var onClose: (() -> Void)?

    // MARK: State
    enum State {
        case completed(amountText: String?, transaction: PaymentTransactionResponse?)
        case declined(message: String?)

        var title: String {
            switch self {
            case .completed: return "Оплата прошла успешно"
            case .declined:  return "Операция отклонена"
            }
        }

        var buttonTitle: String {
            switch self {
            case .completed: return "Вернуться в магазин"
            case .declined:  return "Повторить попытку"
            }
        }

        var icon: UIImage? {
            switch self {
            case .completed: return .iconSuccess
            case .declined:  return .iconFailed
            }
        }
    }

    class func present(from parent: UIViewController, state: State, orderAlreadyBeenPaid: String? = nil, onClose: (() -> Void)? = nil) {
        let vc = PaymentResultViewController(state: state, orderAlreadyBeenPaid: orderAlreadyBeenPaid, onClose: onClose)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        parent.present(vc, animated: true)
    }

    // MARK: Init
    init(state: State, orderAlreadyBeenPaid: String? = nil, onClose: (() -> Void)? = nil) {
        self.state = state
        self.onClose = onClose
        self.orderAlreadyBeenPaid = orderAlreadyBeenPaid
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    // MARK: UI
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = 12
        config.contentInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let cpLogoView: CloudPaymentsLogoView = {
        let v = CloudPaymentsLogoView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Constraints
    private var titleToAmountConstraint: NSLayoutConstraint!
    private var titleToMessageConstraint: NSLayoutConstraint!
    private var buttonToAmountConstraint: NSLayoutConstraint!
    private var buttonToMessageConstraint: NSLayoutConstraint!
    private var buttonToSubtitleConstraint: NSLayoutConstraint!

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        apply(state)
    }

    // MARK: Layout
    private func setupLayout() {
        view.addSubview(dimView)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Container subviews
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(messageLabel)
        container.addSubview(amountLabel)
        container.addSubview(actionButton)
        container.addSubview(cpLogoView)

        // Icon
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 180),
            iconView.widthAnchor.constraint(equalToConstant: 180)
        ])

        // Title
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])

        // Subtitle
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])

        // Amount
        NSLayoutConstraint.activate([
            amountLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])
        titleToAmountConstraint = amountLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20)

        // Message
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])
        titleToMessageConstraint = messageLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10)

        // Button
        buttonToAmountConstraint = actionButton.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 40)
        buttonToMessageConstraint = actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40)
        buttonToSubtitleConstraint = actionButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40)

        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Logo
        NSLayoutConstraint.activate([
            cpLogoView.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 40),
            cpLogoView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            cpLogoView.heightAnchor.constraint(equalToConstant: 24),
            cpLogoView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            cpLogoView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
        actionButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
    }

    // MARK: Data -> UI
    private func apply(_ state: State) {
        iconView.image = state.icon
        titleLabel.text = state.title
        actionButton.configuration?.title = state.buttonTitle

        amountLabel.isHidden = true
        messageLabel.isHidden = true
        subtitleLabel.isHidden = true

        titleToAmountConstraint.isActive = false
        titleToMessageConstraint.isActive = false
        buttonToAmountConstraint.isActive = false
        buttonToMessageConstraint.isActive = false
        buttonToSubtitleConstraint.isActive = false

        switch state {
        case .completed(let amountText, _):
            
            if orderAlreadyBeenPaid == .orderAlreadyBeenPaid {
                titleLabel.text = orderAlreadyBeenPaid
            } else {
                titleLabel.text = state.title
            }
            
            subtitleLabel.text = .orderPaid
            subtitleLabel.isHidden = false
            
            let hasAmount: Bool = {
                if let t = amountText { return !t.isEmpty }
                return false
            }()

            if hasAmount {
                amountLabel.text = amountText
                amountLabel.isHidden = false
                titleToAmountConstraint.isActive = true
                buttonToAmountConstraint.isActive = true
            } else {
                buttonToSubtitleConstraint.isActive = true
            }

        case .declined(let message):
            var text: String
            if let m = message, !m.isEmpty {
                if m.contains("#") {
                    text = m.components(separatedBy: "#").joined(separator: "\n")
                } else {
                    text = m
                }
            } else {
                text = .errorDescription
            }
            messageLabel.text = text
            messageLabel.isHidden = false
            titleToMessageConstraint.isActive = true
            buttonToMessageConstraint.isActive = true
        }
    }

    // MARK: Actions
    @objc private func primaryTapped() {
        dismiss(animated: true) {
            self.delegate?.paymentResultPrimaryTapped(state: self.state)
            self.onClose?()
        }
    }
}
