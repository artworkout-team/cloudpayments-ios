//
//  PaymentViewModel.swift
//  demo
//
//  Created by Cloudpayments on 27.06.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

// MARK: - PaymentViewModelType

enum PaymentViewModelType: Codable {
    case publicId
    case amount
    case currency
    case invoiceId
    case description
    case accountId
    case email
    case jsonData
    
    var title: String {
        switch self {
        case .publicId:
            return "PublicId"
        case .amount:
            return "Amount"
        case .currency:
            return "Currency (Optional)"
        case .invoiceId:
            return "InvoiceId (Optional)"
        case .description:
            return "Description (Optional)"
        case .accountId:
            return "AccountId (Optional)"
        case .email:
            return "Email (Optional)"
        case .jsonData:
            return "JsonData (Optional)"
        }
    }
    
    var `default`: String {
        switch self {
        case .publicId:
            return "test_api_00000000000000000000002"
        case .amount:
            return "100"
        case .currency:
            return "RUB"
        case .invoiceId:
            return "AB1234"
        case .description:
            return "A basket of oranges"
        case .accountId:
            return "AB12"
        case .email:
            return "test@cp.ru"
        case .jsonData:
            return "{\"name\": \"Ivan\"}"
        }
    }
    
    var placeholder: String {
        return "Введите текст"
    }
}

// MARK: - PaymentViewModel

struct PaymentViewModel: Codable {
    
    private static var key: String {
        return "PaymentViewModel_Key"
    }
    
    let type: PaymentViewModelType
    var text: String?
    
    init(_ type: PaymentViewModelType) {
        self.type = type
        self.text = type.default
    }
    
    static func getViewModel() -> [PaymentViewModel] {
        guard let data = UserDefaults.standard.data(forKey: PaymentViewModel.key),
              let array = try? JSONDecoder().decode([PaymentViewModel].self, from: data)
        else {
            return [
                .init(.publicId),
                .init(.amount),
                .init(.currency),
                .init(.invoiceId),
                .init(.description),
                .init(.accountId),
                .init(.email),
                .init(.jsonData)
            ]
        }
        
        return array
    }
    
    static func saving(_ model: [PaymentViewModel]) {
        let data = try? JSONEncoder().encode(model)
        UserDefaults.standard.set(data, forKey: PaymentViewModel.key)
        UserDefaults.standard.synchronize()
    }
}



// MARK: - DemoViewCell

final class DemoViewCell: UITableViewCell {
    
    static let reuseIdentifier = String(describing: DemoViewCell.self)
    
    // MARK: - Private UI
    
    private let containerView = UIView()
    private let demoLabel = UILabel()
    private let demoTextField = UITextField()
    
    private let borderBlueColor = UIColor(
        red: 0.25,
        green: 0.42,
        blue: 0.95,
        alpha: 1
    )
    
    // MARK: - Init
    
    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
        setupTextField()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        demoTextField.removeTarget(nil, action: nil, for: .editingChanged)
        demoTextField.text = nil
        demoTextField.placeholder = nil
        demoLabel.text = nil
    }
    
    // MARK: - Public methods
    
    func setupView(viewModel: PaymentViewModel) {
        demoLabel.text = viewModel.type.title
        demoTextField.placeholder = viewModel.type.placeholder
        demoTextField.text = viewModel.text
    }
    
    func addTarget(_ target: Any, action: Selector, row: Int) {
        demoTextField.tag = row
        demoTextField.addTarget(target, action: action, for: .editingChanged)
    }
    
    // MARK: - Private methods
    
    private func setupView() {
        selectionStyle = .none
        
        backgroundColor = .clear
        contentView.backgroundColor = .white
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 18
        containerView.layer.borderWidth = 0
        containerView.layer.borderColor = nil
        containerView.clipsToBounds = true
        
        demoLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        demoLabel.textColor = .black
        demoLabel.numberOfLines = 0
        
        contentView.addSubview(containerView)
        containerView.addSubview(demoLabel)
        containerView.addSubview(demoTextField)
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        demoLabel.translatesAutoresizingMaskIntoConstraints = false
        demoTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            demoLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            demoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            demoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            
            demoTextField.topAnchor.constraint(equalTo: demoLabel.bottomAnchor, constant: 10),
            demoTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            demoTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            demoTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
            demoTextField.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupTextField() {
        demoTextField.backgroundColor = .white
        demoTextField.textColor = .black
        demoTextField.tintColor = borderBlueColor
        demoTextField.font = .systemFont(ofSize: 17, weight: .regular)
        demoTextField.borderStyle = .none
        
        demoTextField.layer.cornerRadius = 14
        demoTextField.layer.borderWidth = 1.5
        demoTextField.layer.borderColor = borderBlueColor.cgColor
        demoTextField.clipsToBounds = true
        
        demoTextField.leftView = UIView(
            frame: CGRect(x: 0, y: 0, width: 14, height: 1)
        )
        demoTextField.leftViewMode = .always
        
        demoTextField.rightView = UIView(
            frame: CGRect(x: 0, y: 0, width: 14, height: 1)
        )
        demoTextField.rightViewMode = .always
        
        demoTextField.autocorrectionType = .no
        demoTextField.autocapitalizationType = .none
        demoTextField.clearButtonMode = .whileEditing
    }
}

// MARK: - FooterActionView

final class FooterActionView: UIView {
    
    enum ButtonType {
        case demo
    }
    
    // MARK: - Public UI
    
    let demoActionButton = UIButton(type: .system)
    
    // MARK: - Public state
    
    var isDualMessagePaymentEnabled: Bool {
        return dualMessageSwitch.isOn
    }
    
    var isRecurrentEnabled: Bool {
        return recurrentSwitch.isOn
    }
    
    var isReceiptEnabled: Bool {
        return receiptSwitch.isOn
    }
    
    // MARK: - Private UI
    
    private let contentView = UIView()
    
    private let dualMessageContainerView = UIView()
    private let dualMessageTitleLabel = UILabel()
    private let dualMessageSwitch = UISwitch()
    private let dualMessageStateLabel = UILabel()
    private let dualMessageStackView = UIStackView()
    
    private let recurrentContainerView = UIView()
    private let recurrentTitleLabel = UILabel()
    private let recurrentSwitch = UISwitch()
    private let recurrentStateLabel = UILabel()
    private let recurrentStackView = UIStackView()
    
    private let receiptContainerView = UIView()
    private let receiptTitleLabel = UILabel()
    private let receiptSwitch = UISwitch()
    private let receiptStateLabel = UILabel()
    private let receiptStackView = UIStackView()
    
    private let borderBlueColor = UIColor(
        red: 0.25,
        green: 0.42,
        blue: 0.95,
        alpha: 1
    )
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
    }
    
    // MARK: - Public methods
    
    func addTarget(target: Any?, action: Selector, _ type: ButtonType) {
        switch type {
        case .demo:
            demoActionButton.addTarget(target, action: action, for: .touchUpInside)
        }
    }
    
    // MARK: - Private methods
    
    private func setupView() {
        backgroundColor = .white
        
        setupContainer(dualMessageContainerView)
        setupContainer(recurrentContainerView)
        setupContainer(receiptContainerView)
        
        setupTitleLabel(dualMessageTitleLabel, text: "Dual message payment")
        setupTitleLabel(recurrentTitleLabel, text: "Add recurrent")
        setupTitleLabel(receiptTitleLabel, text: "Add receipt")
        
        setupStateLabel(dualMessageStateLabel)
        setupStateLabel(recurrentStateLabel)
        setupStateLabel(receiptStateLabel)
        
        dualMessageStateLabel.text = "Выключено"
        recurrentStateLabel.text = "Выключено"
        receiptStateLabel.text = "Выключено"
        
        setupSwitchStackView(
            dualMessageStackView,
            switchView: dualMessageSwitch,
            label: dualMessageStateLabel
        )
        
        setupSwitchStackView(
            recurrentStackView,
            switchView: recurrentSwitch,
            label: recurrentStateLabel
        )
        
        setupSwitchStackView(
            receiptStackView,
            switchView: receiptSwitch,
            label: receiptStateLabel
        )
        
        dualMessageSwitch.addTarget(
            self,
            action: #selector(switchValueChanged(_:)),
            for: .valueChanged
        )
        
        recurrentSwitch.addTarget(
            self,
            action: #selector(switchValueChanged(_:)),
            for: .valueChanged
        )
        
        receiptSwitch.addTarget(
            self,
            action: #selector(switchValueChanged(_:)),
            for: .valueChanged
        )
        
        configureDemoActionButton()
        
        addSubview(contentView)
        
        contentView.addSubview(dualMessageContainerView)
        dualMessageContainerView.addSubview(dualMessageTitleLabel)
        dualMessageContainerView.addSubview(dualMessageStackView)
        
        contentView.addSubview(recurrentContainerView)
        recurrentContainerView.addSubview(recurrentTitleLabel)
        recurrentContainerView.addSubview(recurrentStackView)
        
        contentView.addSubview(receiptContainerView)
        receiptContainerView.addSubview(receiptTitleLabel)
        receiptContainerView.addSubview(receiptStackView)
        
        contentView.addSubview(demoActionButton)
    }
    
    private func configureDemoActionButton() {
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            
            configuration.title = "Запустить SDK"
            configuration.image = UIImage(systemName: "play.fill")
            configuration.imagePlacement = .leading
            configuration.imagePadding = 8
            configuration.baseForegroundColor = .white
            configuration.baseBackgroundColor = .black
            configuration.cornerStyle = .fixed
            configuration.background.cornerRadius = 18
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: 14,
                leading: 20,
                bottom: 14,
                trailing: 20
            )
            
            demoActionButton.configuration = configuration
        } else {
            demoActionButton.setTitle("Запустить SDK", for: .normal)
            demoActionButton.setTitleColor(.white, for: .normal)
            demoActionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            demoActionButton.backgroundColor = .black
            
       
            demoActionButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            demoActionButton.tintColor = .white
            demoActionButton.semanticContentAttribute = .forceLeftToRight
            
        }
        
        demoActionButton.layer.cornerRadius = 18
        demoActionButton.clipsToBounds = true
    }
    
    private func setupContainer(_ view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1.5
        view.layer.borderColor = borderBlueColor.cgColor
        view.clipsToBounds = true
    }
    
    private func setupTitleLabel(_ label: UILabel, text: String) {
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
    }
    
    private func setupStateLabel(_ label: UILabel) {
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .black
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private func setupSwitchStackView(
        _ stackView: UIStackView,
        switchView: UISwitch,
        label: UILabel
    ) {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        
        switchView.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        stackView.addArrangedSubview(switchView)
        stackView.addArrangedSubview(label)
    }
    
    private func setupConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        dualMessageContainerView.translatesAutoresizingMaskIntoConstraints = false
        dualMessageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        dualMessageStackView.translatesAutoresizingMaskIntoConstraints = false
        
        recurrentContainerView.translatesAutoresizingMaskIntoConstraints = false
        recurrentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recurrentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        receiptContainerView.translatesAutoresizingMaskIntoConstraints = false
        receiptTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        receiptStackView.translatesAutoresizingMaskIntoConstraints = false
        
        demoActionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            dualMessageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            dualMessageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dualMessageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dualMessageContainerView.heightAnchor.constraint(equalToConstant: 88),
            
            dualMessageTitleLabel.topAnchor.constraint(equalTo: dualMessageContainerView.topAnchor, constant: 14),
            dualMessageTitleLabel.leadingAnchor.constraint(equalTo: dualMessageContainerView.leadingAnchor, constant: 14),
            dualMessageTitleLabel.trailingAnchor.constraint(equalTo: dualMessageContainerView.trailingAnchor, constant: -14),
            
            dualMessageStackView.topAnchor.constraint(equalTo: dualMessageTitleLabel.bottomAnchor, constant: 10),
            dualMessageStackView.leadingAnchor.constraint(equalTo: dualMessageContainerView.leadingAnchor, constant: 14),
            dualMessageStackView.trailingAnchor.constraint(lessThanOrEqualTo: dualMessageContainerView.trailingAnchor, constant: -14),
            
            recurrentContainerView.topAnchor.constraint(equalTo: dualMessageContainerView.bottomAnchor, constant: 10),
            recurrentContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recurrentContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            recurrentContainerView.heightAnchor.constraint(equalToConstant: 88),
            
            recurrentTitleLabel.topAnchor.constraint(equalTo: recurrentContainerView.topAnchor, constant: 14),
            recurrentTitleLabel.leadingAnchor.constraint(equalTo: recurrentContainerView.leadingAnchor, constant: 14),
            recurrentTitleLabel.trailingAnchor.constraint(equalTo: recurrentContainerView.trailingAnchor, constant: -14),
            
            recurrentStackView.topAnchor.constraint(equalTo: recurrentTitleLabel.bottomAnchor, constant: 10),
            recurrentStackView.leadingAnchor.constraint(equalTo: recurrentContainerView.leadingAnchor, constant: 14),
            recurrentStackView.trailingAnchor.constraint(lessThanOrEqualTo: recurrentContainerView.trailingAnchor, constant: -14),
            
            receiptContainerView.topAnchor.constraint(equalTo: recurrentContainerView.bottomAnchor, constant: 10),
            receiptContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            receiptContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            receiptContainerView.heightAnchor.constraint(equalToConstant: 88),
            
            receiptTitleLabel.topAnchor.constraint(equalTo: receiptContainerView.topAnchor, constant: 14),
            receiptTitleLabel.leadingAnchor.constraint(equalTo: receiptContainerView.leadingAnchor, constant: 14),
            receiptTitleLabel.trailingAnchor.constraint(equalTo: receiptContainerView.trailingAnchor, constant: -14),
            
            receiptStackView.topAnchor.constraint(equalTo: receiptTitleLabel.bottomAnchor, constant: 10),
            receiptStackView.leadingAnchor.constraint(equalTo: receiptContainerView.leadingAnchor, constant: 14),
            receiptStackView.trailingAnchor.constraint(lessThanOrEqualTo: receiptContainerView.trailingAnchor, constant: -14),
            
            demoActionButton.topAnchor.constraint(equalTo: receiptContainerView.bottomAnchor, constant: 20),
            demoActionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            demoActionButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        switch sender {
        case dualMessageSwitch:
            dualMessageStateLabel.text = sender.isOn ? "Включено" : "Выключено"
            
        case recurrentSwitch:
            recurrentStateLabel.text = sender.isOn ? "Включено" : "Выключено"
            
        case receiptSwitch:
            receiptStateLabel.text = sender.isOn ? "Включено" : "Выключено"
            
        default:
            break
        }
    }
}
