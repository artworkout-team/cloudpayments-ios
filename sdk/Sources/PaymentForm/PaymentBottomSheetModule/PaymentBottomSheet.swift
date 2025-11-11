//
//  PaymentBottomSheetComponent.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit

final class BottomSheetController: BaseViewController {
    
    private let bottomSheetViewModel: BottomSheetViewModelProtocol
    private let contentVC: UIViewController
    
    private var containerView = UIView()
    private var dimmingView = UIView()
    private var containerBottomConstraint: NSLayoutConstraint?
    private var containerHeightConstraint: NSLayoutConstraint?
    private var panGesture: UIPanGestureRecognizer?
    
    var onDismiss: ((_ isSwipe: Bool) -> Void)?
    
    // MARK: - Init
    init(viewModel: BottomSheetViewModelProtocol, content: UIViewController) {
        self.bottomSheetViewModel = viewModel
        self.contentVC = content
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDimming()
        setupContainer()
        layoutContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.view.layoutIfNeeded()
            self.animateIn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.recalculateBottomSheetHeight()
            }
        }
    }
    
    // MARK: - Keyboard
    override func onKeyboardWillShow(_ notification: Notification) {
        super.onKeyboardWillShow(notification)
        containerBottomConstraint?.constant = -keyboardFrame.height
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    override func onKeyboardWillHide(_ notification: Notification) {
        super.onKeyboardWillHide(notification)
        containerBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    // MARK: - Setup
    private func setupDimming() {
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmingView)
        
        NSLayoutConstraint.activate([
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeSheet))
        dimmingView.addGestureRecognizer(tap)
    }
    
    private func setupContainer() {
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = bottomSheetViewModel.cornerRadius
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let maxHeight = containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.9)
        maxHeight.priority = .required
        maxHeight.isActive = true
        
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint?.isActive = true
        
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture?.delegate = self
        if let panGesture { containerView.addGestureRecognizer(panGesture) }
    }
    
    private func layoutContent() {
        addChild(contentVC)
        containerView.addSubview(contentVC.view)
        contentVC.didMove(toParent: self)
        
        contentVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        if let content = contentVC as? BottomSheetPaymentOptionsContentViewController {
            content.onContentChanged = { [weak self] in
                self?.recalculateBottomSheetHeight()
            }
        }
        
        DispatchQueue.main.async {
            self.recalculateBottomSheetHeight()
        }
    }
    
    private func recalculateBottomSheetHeight() {
        view.layoutIfNeeded()
        contentVC.view.layoutIfNeeded()
        
        let scrollView = contentVC.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
        let contentHeight = scrollView?.contentSize.height ?? contentVC.view.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        ).height
        
        let targetHeight = max(160, min(contentHeight, view.bounds.height * 0.9))
        
        if let old = containerHeightConstraint {
            old.isActive = false
            containerView.removeConstraint(old)
            containerHeightConstraint = nil
        }
        
        let newConstraint = containerView.heightAnchor.constraint(equalToConstant: targetHeight)
        containerHeightConstraint = newConstraint
        newConstraint.isActive = true
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Animation
    private func animateIn() {
        UIView.animate(withDuration: 0.3,
                       delay: 0.05,
                       options: [.curveEaseOut]) {
            self.dimmingView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let scrollView = contentVC.view.subviews
            .compactMap { ($0 as? UIScrollView) ?? $0.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView }
            .first
        
        let translation = gesture.translation(in: view).y
        let velocity = gesture.velocity(in: view).y
        
        switch gesture.state {
        case .began:
            if let scrollView, scrollView.contentOffset.y <= 0, velocity > 0 {
                scrollView.isScrollEnabled = false
            }
            
        case .changed:
            if let scrollView {
                if scrollView.contentOffset.y <= 0 && translation > 0 {
                    scrollView.contentOffset = .zero
                    containerView.transform = CGAffineTransform(translationX: 0, y: translation)
                } else {
                    scrollView.isScrollEnabled = true
                }
            } else {
                containerView.transform = CGAffineTransform(translationX: 0, y: max(translation, 0))
            }
            
        case .ended, .cancelled:
            if let scrollView { scrollView.isScrollEnabled = true }
            
            if containerView.transform.ty > 120 || velocity > 1000 {
                closeSheet(isSwipe: true)
            } else {
                UIView.animate(withDuration: 0.25,
                               delay: 0,
                               options: [.curveEaseOut]) {
                    self.containerView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    @objc private func closeSheetFromTap() {
        closeSheet(isSwipe: false)
    }
    
    func closeSheetFromSwipe() {
        closeSheet(isSwipe: true)
    }
    
    @objc private func closeSheet(isSwipe: Bool) {
        view.endEditing(true)
        UIView.animate(withDuration: 0.2, animations: {
            self.dimmingView.alpha = 0
            self.containerBottomConstraint?.constant = self.view.bounds.height
            self.view.layoutIfNeeded()
        }) { _ in
            self.onDismiss?(isSwipe)
            if self.presentingViewController != nil {
                self.dismiss(animated: false)
            } else {
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
        }
    }
        
    func present(in parent: UIViewController) {
        parent.addChild(self)
        view.frame = parent.view.bounds
        parent.view.addSubview(view)
        parent.view.bringSubviewToFront(view)
        didMove(toParent: parent)
    }
}

// MARK: - Gesture Delegate
extension BottomSheetController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        if touch.view is UITextField || touch.view is UIControl { return false }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
