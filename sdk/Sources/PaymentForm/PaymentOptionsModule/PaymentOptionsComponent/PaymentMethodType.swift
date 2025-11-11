//
//  PaymentMethodType.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

public enum PaymentMethodType: String, CaseIterable {
    case tpay = "TinkoffPay"
    case sberPay = "SberPay"
    case sbp = "Sbp"
    case card = "Card"
    case dolyame = "Dolyame"
}

extension PaymentMethodType {
    
    var buttonTitle: String? {
        switch self {
        case .card: return "Банковская карта"
        case .tpay, .sbp, .sberPay: return nil
        case .dolyame: return nil
        }
    }
    
    var buttonIcon: UIImage? {
        switch self {
        case .card: return nil
        case .tpay: return .iconTPay
        case .sbp: return .iconSbp
        case .sberPay: return .iconSberPay
        case .dolyame: return .iconDolyame
        }
    }
    
    var additionalButtonIcon: UIImage? {
        switch self {
        case .card: return .iconCardAdditional
        case .tpay: return .iconTpayAdditional
        case .sbp: return .iconSbpAdditional
        case .sberPay: return .iconSberPayAdditional
        case .dolyame: return .iconDolyameAdditional
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .card: return .colorBlue
        case .tpay: return .tpayButtonColor
        case .sbp: return .sbpButtonColor
        case .sberPay: return .sberPayButtonColor
        case .dolyame: return .black
        }
    }
    
    var titleText: String {
        switch self {
        case .sberPay: return .payResponseSberPay
        case .tpay: return .payResponseTPay
        case .sbp: return .payResponseSbp
        case .card: return .payResponseCardPay
        case .dolyame: return .payResponseDolyame
        }
    }
    
    var methodLogoImage: UIImage? {
        switch self {
        case .card: return nil
        case .tpay: return .iconTPay
        case .sberPay: return .iconMethodSberPay
        case .sbp: return nil
        case .dolyame: return .iconMethodDolyame
        }
    }
    
    var presentViewController: ((UIViewController, PaymentConfiguration) -> Void)? {
        switch self {
        case .tpay:
            return { viewController, configuration in
                ProgressTPayViewController.present(with: configuration, from: viewController)
            }
        case .sberPay:
            return { viewController, configuration in
                ProgressSberPayViewController.present(with: configuration, from: viewController)
            }
        case .sbp:
            return { viewController, configuration in
                ProgressSbpViewController.present(with: configuration, from: viewController)
            }
        case .card:
            return { viewController, configuration in
                PaymentCardViewController.present(with: configuration, from: viewController)
            }
        case .dolyame:
            return { viewController, configuration in
                ProgressDolyameViewController.present(with: configuration, from: viewController)
            }
        }
    }
}
