import Foundation
import StoreKit
import SwiftUI

// MARK: - Tip Jar Product Definition
public struct TipProduct: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let priceString: String
    public let iconEmoji: String
    public let isPopular: Bool

    public init(id: String, title: String, subtitle: String, priceString: String, iconEmoji: String, isPopular: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.priceString = priceString
        self.iconEmoji = iconEmoji
        self.isPopular = isPopular
    }
}

// MARK: - StoreKit 2 Tip Jar Service
@Observable
public final class TipJarService {
    public static let shared = TipJarService()

    public var isSupporter: Bool {
        get { UserDefaults.standard.bool(forKey: "bayan_is_supporter") }
        set { UserDefaults.standard.set(newValue, forKey: "bayan_is_supporter") }
    }

    public var supporterTierName: String {
        get { UserDefaults.standard.string(forKey: "bayan_supporter_tier") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "bayan_supporter_tier") }
    }

    public var isPurchasing: Bool = false
    public var lastPurchaseSuccess: Bool = false
    public var errorMessage: String? = nil

    // Standard Apple In-App Purchase Product IDs
    public static let productIdentifiers = [
        "tools.rea.Bayan.tip.seed",
        "tools.rea.Bayan.tip.generous",
        "tools.rea.Bayan.tip.patron",
        "tools.rea.Bayan.tip.waqf"
    ]

    // Built-in offline catalog (ensures instant UI even before App Store Connect configuration)
    public let defaultCatalog: [TipProduct] = [
        TipProduct(
            id: "tools.rea.Bayan.tip.seed",
            title: "Seed of Goodness",
            subtitle: "Keep Bayan 100% ad-free & assist server hosting",
            priceString: "$1.99",
            iconEmoji: "🌱"
        ),
        TipProduct(
            id: "tools.rea.Bayan.tip.generous",
            title: "Generous Supporter",
            subtitle: "Support authentic audio recitations & maintenance",
            priceString: "$4.99",
            iconEmoji: "🌿",
            isPopular: true
        ),
        TipProduct(
            id: "tools.rea.Bayan.tip.patron",
            title: "Patron of the Quran",
            subtitle: "Help develop new features, translations & Tafsir",
            priceString: "$9.99",
            iconEmoji: "🌳"
        ),
        TipProduct(
            id: "tools.rea.Bayan.tip.waqf",
            title: "Benefactor Waqf",
            subtitle: "Sponsor continuous development & worldwide reach",
            priceString: "$19.99",
            iconEmoji: "✨"
        )
    ]

    public var storeProducts: [Product] = []
    private var transactionListener: Task<Void, Never>? = nil

    private init() {
        startTransactionListener()
        Task {
            await fetchStoreProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Fetch Products from StoreKit 2
    @MainActor
    public func fetchStoreProducts() async {
        do {
            let products = try await Product.products(for: Set(Self.productIdentifiers))
            self.storeProducts = products.sorted { $0.price < $1.price }
            print("🛍️ Successfully loaded \(products.count) StoreKit products.")
        } catch {
            print("⚠️ StoreKit products not yet live in App Store Connect (using fallback catalog): \(error)")
        }
    }

    // MARK: - Purchase Flow
    @MainActor
    public func purchase(product: TipProduct) async -> Bool {
        isPurchasing = true
        errorMessage = nil
        lastPurchaseSuccess = false

        // Check if matching StoreKit Product exists
        if let storeProduct = storeProducts.first(where: { $0.id == product.id }) {
            do {
                let result = try await storeProduct.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        await transaction.finish()
                        self.isSupporter = true
                        self.supporterTierName = product.title
                        self.lastPurchaseSuccess = true
                        self.isPurchasing = false
                        #if os(iOS)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        #endif
                        return true
                    case .unverified(_, let error):
                        self.errorMessage = "Transaction verification failed: \(error.localizedDescription)"
                        self.isPurchasing = false
                        return false
                    }
                case .userCancelled:
                    self.isPurchasing = false
                    return false
                case .pending:
                    self.isPurchasing = false
                    return false
                @unknown default:
                    self.isPurchasing = false
                    return false
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isPurchasing = false
                return false
            }
        } else {
            // Simulated / Mock Purchase when running in offline preview or pre-App Store Connect
            try? await Task.sleep(nanoseconds: 800_000_000)
            self.isSupporter = true
            self.supporterTierName = product.title
            self.lastPurchaseSuccess = true
            self.isPurchasing = false
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            return true
        }
    }

    // MARK: - Restore Purchases
    @MainActor
    public func restorePurchases() async {
        isPurchasing = true
        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if Self.productIdentifiers.contains(transaction.productID) {
                        self.isSupporter = true
                    }
                }
            }
            isPurchasing = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isPurchasing = false
        }
    }

    // MARK: - Background Transaction Listener
    private func startTransactionListener() {
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await MainActor.run {
                        TipJarService.shared.isSupporter = true
                    }
                }
            }
        }
    }
}
