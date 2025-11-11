//
//  SBMenuView.swift
//  Solar Bloom
//
//

import SwiftUI

struct SBMenuView: View {
    @State private var showGame = false
    @State private var showAchievement = false
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var showDailyReward = false
    @State private var showShop = false
    
    @StateObject var shopVM = CPShopViewModel()
    
    var body: some View {
        
        ZStack {
            
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    Image(.personImgSB)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:280)
                    
                    Spacer()
                    
                    
                    
                }
            }.ignoresSafeArea()
            
            HStack {
                
                VStack {
                    Button {
                        showDailyReward = true
                    } label: {
                        Image(.dailyIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:85)
                    }
                    
                    Spacer()
                }.padding(35)
                
                Spacer()
                VStack(spacing: 0) {
                    
                    ZZCoinBg()
                    
                    Image(.menuLogoSB)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:142)
                    
                    
                    Button {
                        showGame = true
                    } label: {
                        Image(.playIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:80)
                    }
                    
                }
                
                Spacer()
                
                VStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(.settingsIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:85)
                    }
                    
                    Spacer()
                    
                    Button {
                        showShop = true
                    } label: {
                        Image(.shopIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:85)
                    }
                    
                    Spacer()
                    
                    Button {
                        showAchievement = true
                    } label: {
                        Image(.achievementsIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:85)
                    }
                }.padding(35)
            }
            
            
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBgSB)
                        .resizable()
                        .edgesIgnoringSafeArea(.all)
                        .scaledToFill()
                }
            )
            .fullScreenCover(isPresented: $showGame) {
//                GameView()
            }
            .fullScreenCover(isPresented: $showAchievement) {
                SBAchievementsView()
            }
            .fullScreenCover(isPresented: $showSettings) {
                SBSettingsView()
            }
            .fullScreenCover(isPresented: $showDailyReward) {
                SBDailyView()
            }
            .fullScreenCover(isPresented: $showShop) {
                SBShopView(viewModel: shopVM)
            }
        
    }
}

#Preview {
    SBMenuView()
}
