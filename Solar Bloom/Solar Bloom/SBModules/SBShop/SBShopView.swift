//
//  SBShopView.swift
//  Solar Bloom
//
//

import SwiftUI

struct SBShopView: View {
    @StateObject var user = ZZUser.shared
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CPShopViewModel
    @State var category: JGItemCategory = .skin
    var body: some View {
        ZStack {
            
            ZStack {
                
                Image(.viewBgSB)
                    .resizable()
                    .scaledToFit()
                
                VStack {
                
                    Image(.shopTextSB)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                        
                    
                    Spacer()
                    
                    ZZCoinBg()
                }.padding(.top, 20).padding(.bottom, 10)
                
                VStack {
                    
                    HStack {
                        
                        ForEach(category == .skin ? viewModel.shopSkinItems :viewModel.shopBgItems, id: \.self) { item in
                            achievementItem(item: item, category: category == .skin ? .skin : .background)
                            
                        }
                        
                        
                    }
                    
                }
                
                HStack {
                    
                    VStack(spacing: 15) {
                        Button {
                            category = .skin
                        } label: {
                            Image(category == .skin ? .skinsTextSB: .skinsOffTextSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:40)
                        }
                        
                        Button {
                            category = .background
                        } label: {
                            Image(category == .background ? .bgTextSB:.bgOffTextSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:40)
                        }
                    }
                    
                    Spacer()
                }
                
            }.frame(height: 270)
            
            
            
            VStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        
                        
                    } label: {
                        Image(.backIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:50)
                    }
                    
                    Spacer()
                    
                }.padding()
                Spacer()
                
                
                
            }
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBgSB)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                }
            )
    }
    
    @ViewBuilder func achievementItem(item: JGItem, category: JGItemCategory) -> some View {
        ZStack {
            
            Image(item.icon)
                .resizable()
                .scaledToFit()
            VStack {
                Spacer()
                Button {
                    viewModel.selectOrBuy(item, user: user, category: category)
                } label: {
                    
                    if viewModel.isPurchased(item, category: category) {
                        ZStack {
                            Image(viewModel.isCurrentItem(item: item, category: category) ? .usedBtnBgSB : .useBtnBgSB)
                                .resizable()
                                .scaledToFit()
                            
                        }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 50:42)
                        
                    } else {
                        Image(.hundredCoinsSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 50:42)
                            .opacity(viewModel.isMoneyEnough(item: item, user: user, category: category) ? 1:0.5)
                    }
                    
                    
                }
            }.offset(y: 8)
            
        }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 300:145)
        
    }
}

#Preview {
    SBShopView(viewModel: CPShopViewModel())
}
