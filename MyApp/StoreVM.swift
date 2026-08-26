import Foundation
import StoreKit
import UIKit

@Observable
@MainActor
final class StoreVM {
    private(set) var subscriptions: [Product] = []
    private(set) var hasLoadedEntitlements = false
    private(set) var hasActiveSubscription = false
    var isLoading = true

    // Match these exactly with your App Store Connect product IDs
    private let productIds = [
        "themuscleclub.subscription.yearly",
        "themuscleclub.subscription.weekly"
    ]

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = Task { [weak self] in
            guard let self else { return }
            for await result in StoreKit.Transaction.updates {
                guard let transaction = try? self.checkVerified(result) else { continue }
                await self.updateCustomerProductStatus()
                await transaction.finish()
            }
        }
        Task { [weak self] in
            guard let self else { return }
            await self.requestProducts()
            await self.updateCustomerProductStatus()
            self.isLoading = false
        }
    }

    func requestProducts() async {
        do {
            subscriptions = try await Product.products(for: productIds)
        } catch {
            print("⚠️ StoreVM: failed to load products — \(error)")
            subscriptions = []
        }
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        // iOS 17+ requires an explicit UIWindowScene for the purchase sheet to appear.
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first

        let result: Product.PurchaseResult
        if let scene {
            result = try await product.purchase(confirmIn: scene)
        } else {
            result = try await product.purchase()
        }
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func refreshEntitlements() async {
        try? await AppStore.sync()
        await updateCustomerProductStatus()
    }

    func updateCustomerProductStatus() async {
        var owned = Set<String>()
        for await result in StoreKit.Transaction.currentEntitlements {
            guard let t = try? checkVerified(result),
                  case .autoRenewable = t.productType else { continue }
            owned.insert(t.productID)
        }
        let resolved: [Product]
        if owned.isEmpty {
            resolved = []
        } else if !subscriptions.isEmpty {
            resolved = subscriptions.filter { owned.contains($0.id) }
        } else {
            resolved = (try? await Product.products(for: Array(owned))) ?? []
        }
        hasLoadedEntitlements = true
        hasActiveSubscription = !resolved.isEmpty
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let signed): return signed
        }
    }
}
