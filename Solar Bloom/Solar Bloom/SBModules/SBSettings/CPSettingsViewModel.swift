//
//  CPSettingsViewModel.swift
//  Solar Bloom
//
//


import SwiftUI

class CPSettingsViewModel: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("vibraEnabled") var vibraEnabled: Bool = true
}
