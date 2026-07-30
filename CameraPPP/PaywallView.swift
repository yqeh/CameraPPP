//
//  PaywallView.swift
//  CameraPPP
//
//  付費訂閱畫面
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var trialManager: TrialManager
    @Binding var isPresented: Bool

    @State private var selectedPlan: PaywallPlan = .yearly

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featureSection
                    planSection
                    actionSection
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }

            if subscriptionManager.isLoading {
                Color.black.opacity(0.45).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
        }
        .alert(isPresented: $subscriptionManager.showAlert) {
            Alert(
                title: Text("Premium"),
                message: Text(subscriptionManager.alertMessage ?? ""),
                dismissButton: .default(Text("OK")) {
                    if subscriptionManager.isPremium {
                        isPresented = false
                    }
                }
            )
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundColor(.yellow)

            Text(AppLanguage.current.localized(
                "Upgrade to Premium",
                "升級至進階版"
            ))
            .font(.title.bold())
            .foregroundColor(.white)

            if trialManager.isTrialActive {
                Text(trialManager.remainingTrialText)
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else {
                Text(AppLanguage.current.localized(
                    "Your free trial has ended. Subscribe to continue using all features.",
                    "免費試用已結束，訂閱後可繼續使用完整功能。"
                ))
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            }
        }
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            paywallFeature(icon: "video.fill", text: AppLanguage.current.localized(
                "Unlimited video recording",
                "無限制錄影"
            ))
            paywallFeature(icon: "calendar", text: AppLanguage.current.localized(
                "Scheduled recording",
                "排程錄影"
            ))
            paywallFeature(icon: "scissors", text: AppLanguage.current.localized(
                "Video trimmer tools",
                "影片剪輯工具"
            ))
            paywallFeature(icon: "xmark.circle", text: AppLanguage.current.localized(
                "Remove ads",
                "移除廣告"
            ))
        }
        .padding(20)
        .background(Color(white: 0.12))
        .cornerRadius(16)
    }

    private var planSection: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .monthly,
                title: AppLanguage.current.localized("Monthly", "月訂閱"),
                price: subscriptionManager.monthlyProduct?.displayPrice ?? SubscriptionConfig.fallbackMonthlyPrice,
                subtitle: AppLanguage.current.localized("Billed every month", "每月自動續訂")
            )

            planCard(
                plan: .yearly,
                title: AppLanguage.current.localized("Yearly", "年訂閱"),
                price: subscriptionManager.yearlyProduct?.displayPrice ?? SubscriptionConfig.fallbackYearlyPrice,
                subtitle: AppLanguage.current.localized("Best value - save 75%", "最划算 - 省 75%"),
                badge: AppLanguage.current.localized("RECOMMENDED", "推薦")
            )
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await purchaseSelectedPlan()
                }
            } label: {
                Text(AppLanguage.current.localized("Subscribe Now", "立即訂閱"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(14)
            }

            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            } label: {
                Text(AppLanguage.current.localized("Restore Purchases", "恢復購買"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            if !trialManager.isTrialActive {
                Button {
                    isPresented = false
                } label: {
                    Text(AppLanguage.current.localized("Maybe Later", "稍後再說"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text(AppLanguage.current.localized(
                "Payment will be charged to your Apple ID. Subscription renews automatically unless canceled at least 24 hours before the end of the current period.",
                "費用將從 Apple ID 扣款。訂閱將自動續訂，除非在目前期間結束前至少 24 小時取消。"
            ))
            .font(.caption2)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                if let termsURL = URL(string: SubscriptionConfig.termsOfUseURL) {
                    Link(AppLanguage.current.localized("Terms of Use", "使用條款"), destination: termsURL)
                }

                if let privacyURL = URL(string: SubscriptionConfig.privacyPolicyURL) {
                    Link(AppLanguage.current.localized("Privacy Policy", "隱私權政策"), destination: privacyURL)
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.top, 8)
    }

    private func paywallFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red.opacity(0.85))
                .frame(width: 22)
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 15))
            Spacer()
        }
    }

    private func planCard(
        plan: PaywallPlan,
        title: String,
        price: String,
        subtitle: String,
        badge: String? = nil
    ) -> some View {
        Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)

                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .cornerRadius(6)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(price)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedPlan == plan ? Color.red : Color.gray.opacity(0.4), lineWidth: selectedPlan == plan ? 2 : 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedPlan == plan ? Color.red.opacity(0.12) : Color(white: 0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private func purchaseSelectedPlan() async {
        let product: Product?

        switch selectedPlan {
        case .monthly:
            product = subscriptionManager.monthlyProduct
        case .yearly:
            product = subscriptionManager.yearlyProduct
        }

        guard let product else {
            subscriptionManager.alertMessage = AppLanguage.current.localized(
                "Product not available. Please check your network or try again later.",
                "商品暫不可用，請確認網路或稍後再試。"
            )
            subscriptionManager.showAlert = true
            await subscriptionManager.loadProducts()
            return
        }

        await subscriptionManager.purchase(product)
    }
}

private enum PaywallPlan {
    case monthly
    case yearly
}
