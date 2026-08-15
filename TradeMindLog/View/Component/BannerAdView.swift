//
//  BannerAdView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/08/15.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        
        if let rootViewController = AdMobManager.shared.getRootViewController() {
            banner.rootViewController = rootViewController
        }
        
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

#Preview {
    BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
        .frame(height: 50)
}
