//
//  AdMobManager.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/08/15.
//

import Foundation
import Combine
import GoogleMobileAds
import UIKit

@MainActor
final class AdMobManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdMobManager()
    
    private var interstitialAd: InterstitialAd?
    
    // MARK: - Ad Unit IDs (Debug: Test IDs / Release: Config File)
    var bannerAdUnitID: String {
        #if DEBUG
        // Google Official Test Banner Ad Unit ID
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        return loadConfig(forKey: "BannerAdUnitID") ?? ""
        #endif
    }
    
    var interstitialAdUnitID: String {
        #if DEBUG
        // Google Official Test Interstitial Ad Unit ID
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        return loadConfig(forKey: "InterstitialAdUnitID") ?? ""
        #endif
    }
    
    private override init() {
        super.init()
    }
    
    // MARK: - Load Config from plist
    private func loadConfig(forKey key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "AdMobConfig", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Warning: AdMobConfig.plist file or key '\(key)' not found.")
            return nil
        }
        return dict[key] as? String
    }
    
    // MARK: - Interstitial Ad Logic
    func loadInterstitialAd() {
        let request = Request()
        
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    return
                }
                
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                print("Interstitial ad loaded successfully.")
            }
        }
    }
    
    func showInterstitialAd() {
        guard let interstitialAd = interstitialAd,
              let rootViewController = self.getRootViewController() else {
            print("Ad wasn't ready yet or RootViewController not found.")
            loadInterstitialAd()
            return
        }
        
        interstitialAd.present(from: rootViewController)
    }
    
    // MARK: - FullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad dismissed. Reloading next ad...")
        self.interstitialAd = nil
        loadInterstitialAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        self.interstitialAd = nil
        loadInterstitialAd()
    }
    
    // Helper to get RootViewController safely
    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        return window.rootViewController
    }
}

