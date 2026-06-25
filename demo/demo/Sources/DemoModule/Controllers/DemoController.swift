//
//  DemoController.swift
//  demo
//
//  Created by Cloudpayments on 23.06.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation
import Cloudpayments

// MARK: - DemoViewController

final class DemoController: BaseViewController {
    
    // MARK: - Private properties
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var viewModels = PaymentViewModel.getViewModel()
    private let footer = FooterActionView()
    
    private let footerHeight: CGFloat = 420
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupFooter()
        setupTableView()
        setupGesture()
    }
    
    // MARK: - Private methods
    
    private func setupView() {
        title = "Cloudpayments SDK Demo"
        view.backgroundColor = .white
    }
    
    private func setupFooter() {
        view.addSubview(footer)
        
        footer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            footer.heightAnchor.constraint(equalToConstant: footerHeight)
        ])
        
        footer.addTarget(target: self, action: #selector(run(_:)), .demo)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footer.topAnchor)
        ])
        
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(
            DemoViewCell.self,
            forCellReuseIdentifier: DemoViewCell.reuseIdentifier
        )
        
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func tapAction() {
        view.endEditing(true)
    }
    
    private func getText(_ type: PaymentViewModelType) -> String? {
        for value in viewModels {
            if value.type == type {
                return value.text
            }
        }
        
        return nil
    }
    
    // MARK: - Standard Form
    
    @objc private func run(_ sender: UIButton) {
        
        PaymentViewModel.saving(viewModels)
        
        guard let publicId = getText(.publicId),
              let amount = getText(.amount),
              let currency = getText(.currency),
              let invoiceId = getText(.invoiceId),
              let descript = getText(.description),
              let account = getText(.accountId),
              let email = getText(.email),
              let jsonData = getText(.jsonData)
        else {
            return
        }
        
        let receipt: [String: Any] = [
            "Items": [
                [
                    "label": "Товар",
                    "price": 1.95,
                    "quantity": 1,
                    "amount": 1.95,
                    "vat": 0,
                    "method": 4,
                    "object": 1
                ]
            ],
            "taxationSystem": 0,
            "email": "test@test.ru",
            "amounts": [
                "electronic": 1.95,
                "advancePayment": 0,
                "credit": 0,
                "provision": 0
            ]
        ]
        
        let recurrent = Recurrent(
            interval: "Week",
            period: 1,
            receipt: receipt,
            amount: 730.65
        )
        
//        let payer = PaymentDataPayer(
//            firstName: payerFirstName,
//            lastName: payerLastName,
//            middleName: payerMiddleName,
//            birth: payerBirthday,
//            address: payerAddress,
//            street: payerStreet,
//            city: payerCity,
//            country: payerCountry,
//            phone: payerPhone,
//            postcode: payerPostcode
//        )
        
        var paymentData = PaymentData()
            .setAmount(amount)
            .setCurrency(currency)
            .setCardholderName("CP SDK")
            .setInvoiceId(invoiceId)
            .setDescription(descript)
            .setAccountId(account)
//            .setPayer(payer)
            .setEmail(email)
            .setJsonData(jsonData)
        
        if footer.isReceiptEnabled {
            paymentData = paymentData.setReceipt(receipt)
        }
        
        if footer.isRecurrentEnabled {
            paymentData = paymentData.setRecurrent(recurrent)
        }
        
        let configuration = PaymentConfiguration(
            publicId: publicId,
            paymentData: paymentData,
            delegate: self,
            uiDelegate: self,
            emailBehavior: .optional,
            paymentMethodSequence: [],
            // singlePaymentMode: .tpay,
            useDualMessagePayment: footer.isDualMessagePaymentEnabled,
            showResultScreenForSinglePaymentMode: true
            // successRedirectUrl: "https://ya.ru",
            // failRedirectUrl: "https://ya.ru",
        )
        
        PaymentOptionsViewController.present(with: configuration, from: self)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension DemoController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return viewModels.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DemoViewCell.reuseIdentifier,
            for: indexPath
        ) as? DemoViewCell else {
            return UITableViewCell()
        }
        
        let value = viewModels[indexPath.row]
        
        cell.setupView(viewModel: value)
        cell.addTarget(
            self,
            action: #selector(textFieldEditing(_:)),
            row: indexPath.row
        )
        
        return cell
    }
    
    @objc private func textFieldEditing(_ textField: UITextField) {
        let row = textField.tag
        
        guard viewModels.indices.contains(row) else { return }
        
        viewModels[row].text = textField.text
    }
}

// MARK: - PaymentDelegate

extension DemoController: PaymentDelegate {
    
    func onPaymentClosed() {
        print("Payment form was closed")
    }
    
    func onPaymentFinished(_ transactionId: Int64?) {
        navigationController?.popViewController(animated: true)
        
        if let transactionId = transactionId {
            print("Transaction finished with ID: \(transactionId)")
        }
    }
    
    func onPaymentFailed(_ errorMessage: String?) {
        if let errorMessage = errorMessage {
            print("Transaction failed with error: \(errorMessage)")
        }
    }
}

// MARK: - PaymentUIDelegate

extension DemoController: PaymentUIDelegate {
    
    func paymentFormWillDisplay() {
        print("Payment form will display")
    }
    
    func paymentFormDidDisplay() {
        print("Payment form did display")
    }
    
    func paymentFormWillHide() {
        print("Payment form will hide")
    }
    
    func paymentFormDidHide() {
        print("Payment form did hide")
    }
}
