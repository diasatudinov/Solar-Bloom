import SwiftUI
import SpriteKit
import Combine


// MARK: - App Entry (Landscape only)
@main
struct TBSApp: App {
var body: some Scene {
WindowGroup {
GameRootView()
.preferredColorScheme(.dark)
.onAppear { Orientation.lockLandscape() }
.onDisappear { Orientation.unlockAll() }
}
}
}


// MARK: - Orientation Lock Helper
private enum Orientation {
static func lockLandscape() {
setOrientationMask(.landscape)
UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
UINavigationController.attemptRotationToDeviceOrientation()
}
static func unlockAll() { setOrientationMask(.all) }
private static func setOrientationMask(_ mask: UIInterfaceOrientationMask) {
(UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
AppOrientation.overrideMask = mask
}
}


private final class AppOrientation: UIViewController {
static var overrideMask: UIInterfaceOrientationMask = .landscape
override var supportedInterfaceOrientations: UIInterfaceOrientationMask { AppOrientation.overrideMask }
}


extension UIWindowScene {
var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } }
}


// MARK: - Core Game Models


struct GridPoint: Hashable, Codable { var r: Int; var c: Int }


enum TileType: Codable { case grass }


struct Tile: Identifiable, Codable {
var id: UUID = .init()
var point: GridPoint
var type: TileType = .grass
var occupied: Bool = false
}


enum BuildingKind: String, CaseIterable, Codable {
case farm, barracks, house, tower, king


var cost: Int {
switch self {
case .farm: return 10
case .barracks: return 25
case .house: return 15
case .tower: return 20
case .king: return 0
}
}


var imageName: String {
switch self {
case .farm: return "farm"
case .barracks: return "barracks"
case .house: return "house"
case .tower: return "tower"
case .king: return "king_blue"
}