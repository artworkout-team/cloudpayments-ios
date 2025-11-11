//
//  PaymentConfiguration.swift
//  sdk
//
//  Created by Sergey Iskhakov on 08.10.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

public class PaymentConfiguration {
    let publicId: String
    let paymentData: PaymentData
    let paymentDelegate: PaymentDelegateImpl
    let paymentUIDelegate: PaymentUIDelegateImpl
    let scanner: PaymentCardScanner?
    let emailBehavior: EmailBehaviorType
    let useDualMessagePayment: Bool
    let disableApplePay: Bool
    let apiUrl: String
    var paymentMethodSequence: [PaymentMethodType]
    var successRedirectUrl: String?
    var showResultScreen: Bool
    var failRedirectUrl: String?
    var saveCardSinglePaymentMode: Bool?
   
    public init(publicId: String, paymentData: PaymentData, delegate: PaymentDelegate? = nil, uiDelegate: PaymentUIDelegate? = nil, scanner: PaymentCardScanner? = nil,
    emailBehavior: EmailBehaviorType = .required, paymentMethodSequence: [PaymentMethodType], useDualMessagePayment: Bool = false, disableApplePay: Bool = false, apiUrl: String = CloudpaymentsApi.baseURLString, showResultScreen: Bool = true, successRedirectUrl: String? = nil, failRedirectUrl: String? = nil) {
        self.publicId = publicId
        self.paymentData = paymentData
        self.paymentDelegate = PaymentDelegateImpl.init(delegate: delegate)
        self.paymentUIDelegate = PaymentUIDelegateImpl.init(delegate: uiDelegate)
        self.scanner = scanner
        self.emailBehavior = emailBehavior
        self.useDualMessagePayment = useDualMessagePayment
        self.disableApplePay = disableApplePay
        self.apiUrl = apiUrl
        self.showResultScreen = showResultScreen
        self.successRedirectUrl = successRedirectUrl
        self.failRedirectUrl = failRedirectUrl
        self.paymentMethodSequence = paymentMethodSequence
    }
}

public enum EmailBehaviorType {
    case required
    case hidden
    case optional
}

