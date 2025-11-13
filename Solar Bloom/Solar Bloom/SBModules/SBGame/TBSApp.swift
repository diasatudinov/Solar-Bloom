
import SwiftUI
import SpriteKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .landscape // lock landscape
    }
}

// MARK: - Core Model
enum Player: String, Codable, CaseIterable, Equatable { case human, ai }

struct GridPoint: Hashable, Codable { let x: Int; let y: Int }

enum BuildingKind: String, Codable, Equatable { case farm, house, barracks, tower, king }

struct Building: Identifiable, Codable, Equatable {
    let id = UUID()
    let owner: Player
    let kind: BuildingKind
    var hp: Int
    var pos: GridPoint
}

struct Unit: Identifiable, Codable, Equatable {
    let id = UUID()
    let owner: Player
    var hp: Int = 10
    var atk: Int = 5
    var moveRange: Int = 3
    var pos: GridPoint
}

struct Tile: Codable { var blocked: Bool = false }

enum GameOutcome: String, Codable { case win, lose }

final class GameModel: ObservableObject {
    // Grid
    @Published var width = 16
    @Published var height = 10
    @Published var tiles: [[Tile]]

    // Entities
    @Published var buildings: [Building] = []
    @Published var units: [Unit] = []

    // Economy / turn
    @Published var coins: [Player: Int] = [.human: 10, .ai: 10]
    @Published var maxUnits: [Player: Int] = [.human: 3, .ai: 3] // grows with houses
    @Published var current: Player = .human
    @Published var turn: Int = 1

    // Fog of war
    @Published var visible: Set<GridPoint> = []

    // Selection
    @Published var selectedTile: GridPoint? = nil
    @Published var selectedUnitID: UUID? = nil

    @Published var outcome: GameOutcome? = nil
    
    init(width: Int = 16, height: Int = 10) {
        self.width = width
        self.height = height
        self.tiles = Array(repeating: Array(repeating: Tile(), count: height), count: width)
        bootstrap()
        recalcVisibility()
    }

    private func place(_ kind: BuildingKind, _ owner: Player, _ x: Int, _ y: Int) {
        let hp = (kind == .king) ? 100 : 30
        buildings.append(Building(owner: owner, kind: kind, hp: hp, pos: .init(x: x, y: y)))
    }

    private func bootstrap() {
        // Flat map, place opposing kings and starting economy
        place(.king, .human, 2, height/2)
        place(.king, .ai, width-3, height/2)
        place(.farm, .human, 3, height/2 - 2)
        place(.house, .human, 3, height/2 + 2)
        place(.barracks, .human, 4, height/2)

        place(.farm, .ai, width-4, height/2 - 2)
        place(.house, .ai, width-4, height/2 + 2)
        place(.barracks, .ai, width-5, height/2)

        // One starting unit
        units.append(Unit(owner: .human, pos: .init(x: 5, y: height/2)))
        units.append(Unit(owner: .ai, pos: .init(x: width-6, y: height/2)))
    }

    func inside(_ p: GridPoint) -> Bool { p.x >= 0 && p.y >= 0 && p.x < width && p.y < height }

    func tileFree(_ p: GridPoint) -> Bool {
        guard inside(p) else { return false }
        if buildings.contains(where: { $0.pos == p && $0.hp > 0 }) { return false }
        if units.contains(where: { $0.pos == p && $0.hp > 0 }) { return false }
        return !tiles[p.x][p.y].blocked
    }

    func neighbors(_ p: GridPoint, range: Int) -> [GridPoint] {
        var out: [GridPoint] = []
        for dx in -range...range {
            for dy in -range...range {
                if abs(dx) + abs(dy) <= range {
                    let q = GridPoint(x: p.x+dx, y: p.y+dy)
                    if inside(q) { out.append(q) }
                }
            }
        }
        return out
    }

    func recalcVisibility() {
        visible.removeAll()
        let sources = buildings.filter{ $0.owner == current && $0.hp > 0 } .map{ $0.pos } +
                      units.filter{ $0.owner == current && $0.hp > 0 } .map{ $0.pos }
        for s in sources {
            for p in neighbors(s, range: 3) { visible.insert(p) }
        }
    }

    // MARK: Turn & Economy
    func endTurnAndRunAI() {
        // Income: +1 coin per farm every 2 turns (approximation of "1 per 2 minutes")
        if turn % 2 == 0 {
            let farmsH = buildings.filter{ $0.owner == .human && $0.kind == .farm && $0.hp > 0 }.count
            let farmsA = buildings.filter{ $0.owner == .ai && $0.kind == .farm && $0.hp > 0 }.count
            coins[.human, default: 0] += farmsH
            coins[.ai, default: 0] += farmsA
        }
        // Tower auto-attacks nearest enemy in sight (simple)
        autoTowerAttacks(for: .human)
        autoTowerAttacks(for: .ai)

        // Switch player
        current = (current == .human) ? .ai : .human
        recalcVisibility()

        if current == .ai {
            runVerySimpleAI()
            // back to human
            current = .human
            turn += 1
            recalcVisibility()
        } else {
            turn += 1
        }
        checkVictory()
    }

    private func autoTowerAttacks(for owner: Player) {
        let towers = buildings.filter{ $0.owner == owner && $0.kind == .tower && $0.hp > 0 }
        for tower in towers {
            // pick nearest enemy unit or enemy king within range 4
            let range = 4
            let enemiesU = units.enumerated().filter{ $0.element.owner != owner && $0.element.hp > 0 }
            let enemiesB = buildings.enumerated().filter{ $0.element.owner != owner && $0.element.hp > 0 }
            let candidatesU = enemiesU.compactMap { idx, u -> (Int, Int)? in
                let d = abs(u.pos.x - tower.pos.x) + abs(u.pos.y - tower.pos.y)
                return d <= range ? (0, idx) : nil
            }
            let candidatesB = enemiesB.compactMap { idx, b -> (Int, Int)? in
                let d = abs(b.pos.x - tower.pos.x) + abs(b.pos.y - tower.pos.y)
                return d <= range ? (1, idx) : nil
            }
            if let target = (candidatesU + candidatesB).sorted(by: { $0.0 < $1.0 }).first {
                if target.0 == 0 { units[target.1].hp -= 4 } else { buildings[target.1].hp -= 4 }
            }
        }
        units.removeAll { $0.hp <= 0 }
        buildings.removeAll { $0.hp <= 0 && $0.kind != .king } // King stays to detect defeat
    }

    private func runVerySimpleAI() {
        // 1) If enough coins and under cap → recruit at barracks
        let aiUnitCount = units.filter{ $0.owner == .ai }.count
        if coins[.ai, default: 0] >= 5 && aiUnitCount < maxUnits[.ai, default: 0] {
            if let barr = buildings.first(where: { $0.owner == .ai && $0.kind == .barracks && $0.hp > 0 }) {
                if let spawn = neighbors(barr.pos, range: 1).first(where: { tileFree($0) }) {
                    units.append(Unit(owner: .ai, pos: spawn))
                    coins[.ai, default: 0] -= 5
                }
            }
        }
        // 2) Move units toward human king
        if let hk = buildings.first(where: { $0.owner == .human && $0.kind == .king })?.pos {
            for i in units.indices where units[i].owner == .ai {
                let u = units[i]
                let dx = hk.x - u.pos.x
                let dy = hk.y - u.pos.y
                let step = min(u.moveRange, max(abs(dx), abs(dy)))
                var best = u.pos
                let options = [GridPoint(x: u.pos.x + (dx == 0 ? 0 : (dx>0 ? 1 : -1))*step, y: u.pos.y),
                               GridPoint(x: u.pos.x, y: u.pos.y + (dy == 0 ? 0 : (dy>0 ? 1 : -1))*step)]
                for p in options where inside(p) && tileFree(p) { best = p; break }
                units[i].pos = best
                // Attack if adjacent to human
                if abs(best.x - hk.x) + abs(best.y - hk.y) == 1 {
                    if let kIdx = buildings.firstIndex(where: { $0.owner == .human && $0.kind == .king }) {
                        buildings[kIdx].hp -= units[i].atk
                    }
                }
            }
        }
        cleanupDead()
    }

    private func cleanupDead() {
        units.removeAll { $0.hp <= 0 }
        // allow dead king to remain to detect win; hp can be <=0
    }

    private func checkVictory() {
        let humanKingHP = buildings.first(where: { $0.owner == .human && $0.kind == .king })?.hp ?? 0
        let aiKingHP = buildings.first(where: { $0.owner == .ai && $0.kind == .king })?.hp ?? 0
        if humanKingHP <= 0 { outcome = .lose }
        else if aiKingHP <= 0 { outcome = .win; ZZUser.shared.updateUserMoney(for: 100) }
    }

    // MARK: Player Actions
    func build(_ kind: BuildingKind) {
        guard current == .human, let tile = selectedTile else { return }
        guard kind != .king else { return }
        let cost: Int = {
            switch kind { case .farm: return 6; case .house: return 6; case .barracks: return 8; case .tower: return 8; case .king: return 0 }
        }()
        guard coins[.human, default: 0] >= cost else { return }
        guard tileFree(tile) else { return }
        buildings.append(Building(owner: .human, kind: kind, hp: 30, pos: tile))
        coins[.human, default: 0] -= cost
        if kind == .house { maxUnits[.human, default: 0] += 2 }
        recalcVisibility()
    }

    func recruitSoldier() {
        guard current == .human else { return }
        guard coins[.human, default: 0] >= 5 else { return }
        let count = units.filter{ $0.owner == .human }.count
        guard count < maxUnits[.human, default: 0] else { return }
        guard let barr = buildings.first(where: { $0.owner == .human && $0.kind == .barracks && $0.hp > 0 }) else { return }
        if let spawn = neighbors(barr.pos, range: 1).first(where: { tileFree($0) }) {
            units.append(Unit(owner: .human, pos: spawn))
            coins[.human, default: 0] -= 5
            recalcVisibility()
        }
    }

    func selectTile(_ p: GridPoint) { selectedTile = p }

    func selectUnit(at p: GridPoint) {
        selectedUnitID = units.first(where: { $0.owner == current && $0.pos == p })?.id
    }

    func moveSelectedUnit(to p: GridPoint) {
        guard current == .human, let id = selectedUnitID,
              let idx = units.firstIndex(where: { $0.id == id }), units[idx].hp > 0 else { return }
        let u = units[idx]
        guard abs(u.pos.x - p.x) + abs(u.pos.y - p.y) <= u.moveRange else { return }
        guard tileFree(p) else { return }
        units[idx].pos = p
        recalcVisibility()
    }

    func attack(from p: GridPoint, to q: GridPoint) {
        guard current == .human,
              let aIdx = units.firstIndex(where: { $0.owner == .human && $0.pos == p }) else { return }
        // Attack enemy unit first, else enemy building
        if let eIdx = units.firstIndex(where: { $0.owner == .ai && $0.pos == q }) {
            if abs(p.x - q.x) + abs(p.y - q.y) == 1 {
                units[eIdx].hp -= units[aIdx].atk
                cleanupDead()
            }
            return
        }
        if let bIdx = buildings.firstIndex(where: { $0.owner == .ai && $0.pos == q }) {
            if abs(p.x - q.x) + abs(p.y - q.y) == 1 {
                buildings[bIdx].hp -= units[aIdx].atk
                cleanupDead()
            }
            return
        }
    }
}

// MARK: - SpriteKit Scene (transparent)
final class GameScene: SKScene {
    private func computeLayout(for model: GameModel?) {
        guard let model = model else { return }
        let cols = CGFloat(model.width)
        let rows = CGFloat(model.height)
        let w = size.width
        let h = size.height
        let a = max(1.0, diamondAspect)
        // tileSize must satisfy: cols*(a*tileSize) + (cols-1)*spacing <= w, rows*(tileSize) + (rows-1)*spacing <= h
        let maxByW = (w - (cols - 1)*spacingPx) / (cols * a)
        let maxByH = (h - (rows - 1)*spacingPx) / (rows)
        tileSize = max(4, min(maxByW, maxByH))
        ry = tileSize * 0.5
        rx = ry * a
        stepX = 2 * rx + spacingPx
        stepY = 2 * ry + spacingPx
        // center the grid, origin is center of (0,0) tile
        let usedW = cols * (2*rx) + (cols - 1) * spacingPx
        let usedH = rows * (2*ry) + (rows - 1) * spacingPx
        originX = (w - usedW) * 0.5 + rx
        originY = (h - usedH) * 0.5 + ry
    }


    weak var model: GameModel?
    
    var shopVM = CPShopViewModel()
    
    var tileSize: CGFloat = 56
    // Diamond visuals
    var diamondAspect: CGFloat = 1.15 // width is ~15% larger than height
    var tileFillTexture: SKTexture? = SKTexture(imageNamed: "tile_diamond")
    var spacingPx: CGFloat = 1.0 // 1-point gap between tiles

    // Derived layout
    private var rx: CGFloat = 0 // half-width of diamond
    private var ry: CGFloat = 0 // half-height of diamond
    private var stepX: CGFloat = 0 // center-to-center X
    private var stepY: CGFloat = 0 // center-to-center Y
    private var originX: CGFloat = 0 // center of (0,0)
    private var originY: CGFloat = 0

    private let gridNode = SKNode()
    private let unitsNode = SKNode()
    private let buildingsNode = SKNode()
    private let fogNode = SKNode()

    convenience init(model: GameModel, size: CGSize) {
        self.init(size: size)
        self.model = model
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear // transparency so gradient shows through
        anchorPoint = CGPoint(x: 0, y: 0)
        addChild(gridNode)
        addChild(buildingsNode)
        addChild(unitsNode)
        addChild(fogNode)
        drawAll()
    }

    func drawAll() {
        computeLayout(for: model)
        gridNode.removeAllChildren(); buildingsNode.removeAllChildren(); unitsNode.removeAllChildren(); fogNode.removeAllChildren()
        guard let model = model else { return }
        let w = size.width, h = size.height
        let cols = CGFloat(model.width), rows = CGFloat(model.height)
        // stepX = tileSize * aspect + spacing, stepY = tileSize + spacing
        let tMaxByWidth  = (w / cols - spacingPx) / max(1.0, diamondAspect)
        let tMaxByHeight = (h / rows - spacingPx)
        tileSize = max(4, min(tMaxByWidth, tMaxByHeight))
        // Grid (diamonds)
        for x in 0..<model.width { for y in 0..<model.height {
            let center = posToPoint(.init(x: x, y: y))
            let path = diamondPath(center: center, height: tileSize * 0.98, aspect: diamondAspect)
            let n = SKShapeNode(path: path)
            n.strokeColor = .white.withAlphaComponent(0.15)
            n.lineWidth = 1
            n.isAntialiased = false
            n.lineJoin = .miter
            n.miterLimit = 10
            n.lineCap = .butt
            if let bg = shopVM.currentBgItem {
                n.fillTexture = SKTexture(imageNamed: bg.image)
                n.fillColor = .white
            } else {
                n.fillColor = .clear
            }
        
            n.name = "tile_\(x)_\(y)"
            gridNode.addChild(n)
        }}
        // Buildings
        for b in model.buildings where b.hp > 0 {
            let tex = texture(for: b)
            let sprite = SKSpriteNode(texture: tex)
            sprite.position = posToPoint(b.pos)
            // Fit sprite snugly inside diamond cell (accounting for spacing):
            let renderW = 2*rx - spacingPx
            let renderH = 2*ry - spacingPx
            sprite.size = CGSize(width: renderW * 0.96, height: renderH * 0.96)
            sprite.name = "building_\(b.id)"
            sprite.zPosition = 10
            // HP label
            let hp = label("\(b.kind == .king ? "K" : symbol(for: b.kind)) \(max(0,b.hp))")
            hp.position = CGPoint(x: 0, y: -sprite.size.height*0.55)
            sprite.addChild(hp)
            buildingsNode.addChild(sprite)
        }
        // Units
        for u in model.units where u.hp > 0 {
            let tex = texture(for: u)
            let node = SKSpriteNode(texture: tex)
            node.position = posToPoint(u.pos)
            let renderW = 2*rx - spacingPx
            let renderH = 2*ry - spacingPx
            node.size = CGSize(width: renderW * 0.8, height: renderH * 0.8)
            node.name = "unit_\(u.id)"
            node.zPosition = 20
            let hp = label("\(u.hp)")
            hp.position = CGPoint(x: 0, y: -node.size.height*0.55)
            node.addChild(hp)
            unitsNode.addChild(node)
        }
        // Fog of war (simple mask: cover non-visible tiles for current player)
        for x in 0..<model.width { for y in 0..<model.height {
            let p = GridPoint(x: x, y: y)
            if !model.visible.contains(p) {
                let center = posToPoint(p)
                let fog = SKShapeNode(path: diamondPath(center: center, height: tileSize, aspect: diamondAspect))
                fog.fillColor = .black.withAlphaComponent(0.6)
                fog.strokeColor = .clear
                fog.isAntialiased = false
                fogNode.addChild(fog)
            }
        }}
    }

    private func symbol(for kind: BuildingKind) -> String {
        switch kind { case .farm: return "F"; case .house: return "H"; case .barracks: return "B"; case .tower: return "T"; case .king: return "K" }
    }
    
    private func color(for b: Building) -> SKColor { .clear } // unused with textures
    
    private func label(_ text: String) -> SKLabelNode {
        let l = SKLabelNode(text: text)
        l.fontName = "Menlo-Bold"
        l.fontSize = 12
        l.fontColor = .white
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }

    private func posToPoint(_ p: GridPoint) -> CGPoint {
        // Centers spaced so diamonds leave a 1-pt gap
        let ry = tileSize * 0.5
        let rx = ry * max(1.0, diamondAspect)
        let stepX = 2*rx + spacingPx
        let stepY = 2*ry + spacingPx
        let ox: CGFloat = stepX * 0.5
        let oy: CGFloat = stepY * 0.5
        return CGPoint(x: CGFloat(p.x)*stepX + ox, y: CGFloat(p.y)*stepY + oy)
    }
    private func pointToGrid(_ pt: CGPoint) -> GridPoint {
        let ry = tileSize * 0.5
        let rx = ry * max(1.0, diamondAspect)
        let stepX = 2*rx + spacingPx
        let stepY = 2*ry + spacingPx
        let i = Int((pt.x) / stepX)
        let j = Int((pt.y) / stepY)
        let maxX = (model?.width ?? 1) - 1
        let maxY = (model?.height ?? 1) - 1
        return GridPoint(x: max(0, min(i, maxX)), y: max(0, min(j, maxY)))
    }
    private func diamondPath(center: CGPoint, height: CGFloat, aspect: CGFloat) -> CGPath {
        let ry = height * 0.5
        let rx = ry * max(1.0, aspect) // width radius slightly larger
        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x, y: center.y + ry)) // top
        path.addLine(to: CGPoint(x: center.x + rx, y: center.y)) // right
        path.addLine(to: CGPoint(x: center.x, y: center.y - ry)) // bottom
        path.addLine(to: CGPoint(x: center.x - rx, y: center.y)) // left
        path.closeSubpath()
        return path
    }
    // Texture helpers
    private func texture(for unit: Unit) -> SKTexture {
        SKTexture(imageNamed: unit.owner == .human ? "unit_human" : "unit_ai")
    }
    private func texture(for b: Building) -> SKTexture {
        let who = (b.owner == .human) ? "human" : "ai"
        switch b.kind {
        case .farm: return SKTexture(imageNamed: "b_farm_\(who)")
        case .house: return SKTexture(imageNamed: "b_house_\(who)")
        case .barracks: return SKTexture(imageNamed: "b_barracks_\(who)")
        case .tower: return SKTexture(imageNamed: "b_tower_\(who)")
        case .king:
            if who == "ai" {
                return SKTexture(imageNamed: "b_king_\(who)")
            } else {
                if let skin = shopVM.currentSkinItem {
                    return SKTexture(imageNamed: skin.image)
                } else {
                    return SKTexture(imageNamed: "b_king_\(who)")
                }
            }
            
        }
    }


    // MARK: Touch handling (tap to select/move/attack)
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let m = model, let t = touches.first else { return }
        let loc = t.location(in: self)
        let gp = pointToGrid(loc)

        // If a human unit is selected and tapped a target tile
        if let sel = m.selectedUnitID, let u = m.units.first(where: { $0.id == sel }) {
            // Try attack adjacency first
            if abs(u.pos.x - gp.x) + abs(u.pos.y - gp.y) == 1 {
                m.attack(from: u.pos, to: gp)
                drawAll(); return
            }
            // Else try move
            m.moveSelectedUnit(to: gp)
            drawAll(); return
        }
        // Else, tap prioritizes selecting unit; if none, select tile
        if m.units.contains(where: { $0.owner == m.current && $0.pos == gp }) {
            m.selectUnit(at: gp)
        } else {
            m.selectedUnitID = nil
            m.selectTile(gp)
        }
        drawAll()
    }
}

// MARK: - SwiftUI Shell
struct GameRootView: View {
    @StateObject private var model = GameModel()
    @State private var scene: GameScene = GameScene(size: CGSize(width: 1920, height: 1080))

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // SpriteKit transparent scene
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.scaleMode = .resizeFill
                    scene.backgroundColor = .clear
                    scene.model = model
                    scene.drawAll()
                }
                .onChange(of: model.visible) { _ in scene.drawAll() }
                .onChange(of: model.buildings) { _ in scene.drawAll() }
                .onChange(of: model.units) { _ in scene.drawAll() }
                .onChange(of: model.turn) { _ in scene.drawAll() }

            // HUD & Controls (SwiftUI only)
            VStack(spacing: 12) {
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
                }
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        model.endTurnAndRunAI()
                    } label: {
                        Image(.backIconSB)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:85)
                            .scaleEffect(x: -1, y: 1)
                    }
                    
                }
                //actionBar
            }
            .padding(16)
            
            if let outcome = model.outcome {
                
                if outcome == .win {
                    ZStack {
                        Image(.winBgSB)
                            .resizable()
                            .ignoresSafeArea()
                        
                        VStack(spacing: 30) {
                            Image(.winTextSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                            
                            HStack {
                                
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Image(.menuBtnSB)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                }
                                
                               
                                Spacer()
                                
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Image(.nextBtnSB)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                }
                                
                                
                            }.padding(.horizontal, 32)
                            
                            Image(.hundredCoinsPlusSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                        }
                    }
                } else {
                    ZStack {
                        Image(.loseBgSB)
                            .resizable()
                            .ignoresSafeArea()
                        
                        VStack(spacing: 30) {
                            Image(.loseTextSB)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                            
                            HStack {
                                
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Image(.menuBtnSB)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                }
                                
                                
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Image(.retryBtnSB)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                }
                                
                                
                            }.padding(.horizontal, 32)
                            
                        }
                    }
                }
            }
        }
        .environmentObject(model)
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Turn: \(model.turn)")
                    Text("Current: \(model.current == .human ? "YOU" : "AI")")
                }
            }.frame(width: 160)
            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coins: \(model.coins[.human, default: 0])")
                    Text("Units: \(model.units.filter{ $0.owner == .human }.count) / \(model.maxUnits[.human, default: 0])")
                }
            }.frame(width: 200)
            Spacer()
            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    let hk = model.buildings.first(where: { $0.owner == .human && $0.kind == .king })?.hp ?? 0
                    let ak = model.buildings.first(where: { $0.owner == .ai && $0.kind == .king })?.hp ?? 0
                    Text("Your King HP: \(max(0,hk))")
                    Text("Enemy King HP: \(max(0,ak))")
                }
            }.frame(width: 220)
        }
        .groupBoxStyle(.tinted)
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                buildButton("Farm", kind: .farm)
                buildButton("House", kind: .house)
                buildButton("Barracks", kind: .barracks)
                buildButton("Tower", kind: .tower)
                Button("Recruit Soldier (5)") { model.recruitSoldier() }
                    .buttonStyle(.borderedProminent)
            }
            HStack(spacing: 8) {
                Button("End Turn") { model.endTurnAndRunAI() }
                    .buttonStyle(.bordered)
                Button("Center") { scene.drawAll() }
                    .buttonStyle(.bordered)
                if let sel = model.selectedTile { Text("Selected: (\(sel.x),\(sel.y))") }
                if let uid = model.selectedUnitID, let u = model.units.first(where: {$0.id == uid}) {
                    Text("Unit @ (\(u.pos.x),\(u.pos.y)) HP=\(u.hp)")
                }
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func buildButton(_ title: String, kind: BuildingKind) -> some View {
        Button("\(title)") { model.build(kind) }
            .buttonStyle(.bordered)
    }
}

// MARK: - Small Styles
struct TintedGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.content
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension GroupBoxStyle where Self == TintedGroupBoxStyle {
    static var tinted: TintedGroupBoxStyle { .init() }
}


#Preview {
    GameRootView()
}
