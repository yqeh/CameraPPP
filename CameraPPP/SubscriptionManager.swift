//
//  SubscriptionManager.swift
//  CameraPPP
//
//  StoreKit 2 訂閱管理
//

import Foundation
import Combine
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var yearlyProduct: Product?
    @Published private(set) var isPremium = false
    @Published private(set) var isLoading = false
    @Published var alertMessage: String?
    @Published var showAlert = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: SubscriptionConfig.premiumStatusKey)
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await refreshSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    /// 載入 App Store 商品
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: SubscriptionConfig.allProductIDs)
            monthlyProduct = products.first { $0.id == SubscriptionConfig.monthlyProductID }
            yearlyProduct = products.first { $0.id == SubscriptionConfig.yearlyProductID }
        } catch {
            alertMessage = AppLanguage.current.localized(
                "Unable to load subscription products. Please try again later.",
                "無法載入訂閱方案，請稍後再試。"
            )
            showAlert = true
        }
    }

    /// 購買指定方案
    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshSubscriptionStatus()
                alertMessage = AppLanguage.current.localized(
                    "Subscription activated successfully!",
                    "訂閱已成功啟用！"
                )
                showAlert = true
            case .userCancelled:
                break
            case .pending:
                alertMessage = AppLanguage.current.localized(
                    "Purchase is pending approval.",
                    "購買正在等待核准。"
                )
                showAlert = true
            @unknown default:
                break
            }
        } catch {
            alertMessage = AppLanguage.current.localized(
                "Purchase failed. Please try again.",
                "購買失敗，請再試一次。"
            )
            showAlert = true
        }
    }

    /// 恢復購買
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshSubscriptionStatus()

            if isPremium {
                alertMessage = AppLanguage.current.localized(
                    "Your subscription has been restored.",
                    "訂閱已成功恢復。"
                )
            } else {
                alertMessage = AppLanguage.current.localized(
                    "No active subscription found.",
                    "找不到有效的訂閱。"
                )
            }
            showAlert = true
        } catch {
            alertMessage = AppLanguage.current.localized(
                "Unable to restore purchases.",
                "無法恢復購買，請稍後再試。"
            )
            showAlert = true
        }
    }

    /// 更新訂閱狀態
    func refreshSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard SubscriptionConfig.allProductIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate {
                if expirationDate > Date() {
                    hasActiveSubscription = true
                }
            } else {
                hasActiveSubscription = true
            }
        }

        isPremium = hasActiveSubscription
        UserDefaults.standard.set(hasActiveSubscription, forKey: SubscriptionConfig.premiumStatusKey)
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                guard let transaction = try? await self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshSubscriptionStatus()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
