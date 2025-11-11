//
//  SBAchievementsView.swift
//  Solar Bloom
//
//

import SwiftUI

struct SBAchievementsView: View {
    @StateObject var user = ZZUser.shared
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel = ZZAchievementsViewModel()
    @State private var index = 0
    var body: some View {
        ZStack {
            
            VStack {
                ZStack {
                    
                    
                    HStack(alignment: .top) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                        }
                        
                        Spacer()
                        
                        
                    }.padding(.horizontal)
                }.padding([.top])
                
                Spacer()
                ZStack {
                    Image(.viewBgSB)
                        .resizable()
                    
                    VStack {
                    
                        Image(.achievementsTextSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                            
                        
                        Spacer()
                        
                        ZZCoinBg()
                    }.padding(.top, 20).padding(.bottom, 10)
                    
                        HStack(spacing: 10) {
                            ForEach(viewModel.achievements, id: \.self) { item in
                                ZStack {
                                    VStack {
                                        Image(item.image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:145)
                                            .opacity(item.isAchieved ? 1 : 0.5)
                                        
                                        
                                        Image(.tenCoinsCB)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 40:27)
                                    }.onTapGesture {
                                        if !item.isAchieved {
                                            user.updateUserMoney(for: 10)
                                        }
                                        viewModel.achieveToggle(item)
                                    }
                                }
                            }
                        }
                }.frame(maxWidth: .infinity)
            }
        }.background(
            ZStack {
                Image(.appBgSB)
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
            }
        )
    } 
}

#Preview {
    SBAchievementsView()
}
