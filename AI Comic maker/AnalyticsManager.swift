import Foundation
import Mixpanel

struct AnalyticsEvent {
    static let obPageFinished = "ob_page_finished"
    static let onboardingCompleted = "onboarding_completed"
    static let paywallViewed = "paywall_viewed"
    static let subscriptionPurchaseStarted = "subscription_purchase_started"
    static let subscriptionPurchaseSucceeded = "subscription_purchase_succeeded"
    static let subscriptionPurchaseFailed = "subscription_purchase_failed"
    static let restorePurchasesTapped = "restore_purchases_tapped"
    static let restorePurchasesSucceeded = "restore_purchases_succeeded"
    static let restorePurchasesFailed = "restore_purchases_failed"
    static let trialRewardBannerViewed = "trial_reward_banner_viewed"
    static let dailyRewardClaimed = "daily_reward_claimed"
    static let fishCoinShopViewed = "fish_coin_shop_viewed"
    static let fishCoinPurchaseStarted = "fish_coin_purchase_started"
    static let fishCoinPurchaseSucceeded = "fish_coin_purchase_succeeded"
    static let fishCoinPurchaseFailed = "fish_coin_purchase_failed"
    static let storyGenerationStarted = "story_generation_started"
    static let storyGenerationSucceeded = "story_generation_succeeded"
    static let storyGenerationFailed = "story_generation_failed"
    static let roleCreationStarted = "role_creation_started"
    static let roleCreationSucceeded = "role_creation_succeeded"
    static let imageEditEntered = "image_edit_entered"
    static let imageEditCompleted = "image_edit_completed"
    static let imageOverlayAdded = "image_overlay_added"
    static let textOverlayAdded = "text_overlay_added"
    static let backgroundAdded = "background_added"
    static let imageRegenerationStarted = "image_regeneration_started"
    static let imageRegenerationSucceeded = "image_regeneration_succeeded"
    static let imageRegenerationFailed = "image_regeneration_failed"
    static let imageSaved = "image_saved"
    static let imageSaveFailed = "image_save_failed"
}

enum AnalyticsManager {
    static func track(_ event: String, properties: [String: MixpanelType] = [:]) {
        print("[Analytics] track event=\(event), properties=\(properties)")
        Mixpanel.mainInstance().track(event: event, properties: properties)
    }
}

