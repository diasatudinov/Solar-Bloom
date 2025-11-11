//
//  SBSettingsView.swift
//  Solar Bloom
//
//

import SwiftUI

struct SBSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var settingsVM = CPSettingsViewModel()
    var body: some View {
        ZStack {
            
            VStack {
                
                
                ZStack {
                    
                    Image(.viewBgSB)
                        .resizable()
                        .scaledToFit()
                    
                    VStack {
                        
                        Image(.settingsTextSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                            .padding(.top, 20)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 30) {
                        
                        VStack(spacing: 30) {
                            
                            Image(.soundsTextSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                            
                            Button {
                                withAnimation {
                                    settingsVM.soundEnabled.toggle()
                                }
                            } label: {
                                Image(settingsVM.soundEnabled ? .onSB:.offSB)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:20)
                            }
                        }

                        
                        VStack(spacing: 30) {
                            
                            Image(.musicTextSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                            
                            Button {
                                withAnimation {
                                    settingsVM.vibraEnabled.toggle()
                                }
                            } label: {
                                Image(settingsVM.vibraEnabled ? .onSB:.offSB)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:20)
                            }
                        }
                        
                        Image(.languageTextSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:110)
                            
                                                
                    }.padding(.top, 30)
                }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:300)
                
            }.padding(.top, 50)
            
            VStack {
                ZStack {
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                        }
                        
                        Spacer()
                        
                        ZZCoinBg()
                        
                        Spacer()
                        
                        Image(.backIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                            .opacity(0)
                        
                    }.padding()
                }
                Spacer()
                
            }
        }.frame(maxWidth: .infinity)
            .background(
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
    SBSettingsView()
}
