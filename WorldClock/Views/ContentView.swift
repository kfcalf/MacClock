import SwiftUI
import UniformTypeIdentifiers

/// Main content view with world map and city clocks
struct ContentView: View {
    @StateObject private var viewModel = WorldClockViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // World Map as full background
            WorldMapView(
                cities: viewModel.cities,
                currentTime: viewModel.currentTime,
                centerOnCity: viewModel.selectedCity,
                shouldResetZoom: viewModel.shouldResetMapZoom
            )
            .ignoresSafeArea()
            
            // Floating buttons in top right
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        // Zoom reset button
                        Button(action: {
                            viewModel.resetMapZoom()
                        }) {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("重置地图视图")
                        
                        // Toggle panel button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                viewModel.isPanelVisible.toggle()
                            }
                        }) {
                            Image(systemName: viewModel.isPanelVisible ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                        .buttonStyle(.plain)
                        .help(viewModel.isPanelVisible ? "隐藏时钟面板" : "显示时钟面板")
                    }
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
                
                Spacer()
            }
            
            // Bottom section with city clocks - animated
            if viewModel.isPanelVisible {
                VStack(spacing: 0) {
                    // Header with add button
                    HStack {
                        Text("城市时钟")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.showingCityManager = true
                        }) {
                            Label("添加城市", systemImage: "plus")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // City clocks horizontal scroll with drag reorder
                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(Array(viewModel.cities.enumerated()), id: \.element.id) { index, city in
                                    CityClockCard(
                                        city: city,
                                        style: viewModel.cityClockStyle(for: city),
                                        currentTime: viewModel.currentTime,
                                        isSelected: viewModel.selectedCityId == city.id,
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                viewModel.selectCity(city)
                                            }
                                        },
                                        onDelete: {
                                            withAnimation {
                                                viewModel.removeCity(city)
                                            }
                                        }
                                    )
                                    .id(city.id)
                                    .opacity(viewModel.draggingCityId == city.id ? 0.5 : 1.0)
                                    .onDrag {
                                        viewModel.draggingCityId = city.id
                                        return NSItemProvider(object: city.id.uuidString as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: CityDropDelegate(
                                        city: city,
                                        viewModel: viewModel
                                    ))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geo.frame(in: .named("scroll")).minX
                                    )
                                }
                            )
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // Only update from scroll when not dragging the scrollbar
                            if !viewModel.isScrollbarDragging {
                                let calculatedProgress = min(1.0, max(0, -value / max(1, CGFloat(viewModel.cities.count - 3) * 180)))
                                viewModel.scrollProgress = calculatedProgress
                            }
                        }
                        
                        // Interactive glowing scroll indicator
                        if viewModel.cities.count > 3 {
                            InteractiveGlowingScrollbar(
                                progress: Binding(
                                    get: { viewModel.scrollProgress },
                                    set: { newValue in
                                        viewModel.scrollProgress = newValue
                                        // Calculate target index
                                        let targetIndex = Int(newValue * CGFloat(viewModel.cities.count - 1))
                                        let clampedIndex = max(0, min(targetIndex, viewModel.cities.count - 1))
                                        if clampedIndex < viewModel.cities.count {
                                            withAnimation(.easeOut(duration: 0.15)) {
                                                scrollProxy.scrollTo(viewModel.cities[clampedIndex].id, anchor: .center)
                                            }
                                        }
                                    }
                                ),
                                isDragging: $viewModel.isScrollbarDragging,
                                itemCount: viewModel.cities.count
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }
                    }
                    
                    // Footer with transparency slider and title
                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Slider(value: $viewModel.panelOpacity, in: 0.2...1.0, step: 0.1)
                            .frame(width: 100)
                            .tint(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Text("世界时钟")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .background(
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                        .opacity(viewModel.panelOpacity)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $viewModel.showingCityManager) {
            CityManagementView(viewModel: viewModel)
        }
    }
}

// MARK: - Visual Effect Blur for macOS

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}

// MARK: - City Drop Delegate

struct CityDropDelegate: DropDelegate {
    let city: City
    let viewModel: WorldClockViewModel
    
    func performDrop(info: DropInfo) -> Bool {
        viewModel.draggingCityId = nil
        viewModel.saveCities()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggingId = viewModel.draggingCityId,
              draggingId != city.id,
              let fromIndex = viewModel.cities.firstIndex(where: { $0.id == draggingId }),
              let toIndex = viewModel.cities.firstIndex(where: { $0.id == city.id }) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.cities.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        viewModel.draggingCityId != nil
    }
}

// MARK: - Scroll Offset PreferenceKey

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Interactive Glowing Scrollbar

struct InteractiveGlowingScrollbar: View {
    @Binding var progress: CGFloat
    @Binding var isDragging: Bool
    let itemCount: Int
    
    @State private var dragProgress: CGFloat = 0
    @State private var trackWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let thumbWidth: CGFloat = max(50, trackWidth * 0.15)
            let availableWidth = trackWidth - thumbWidth
            let currentProgress = isDragging ? dragProgress : progress
            let thumbOffset = currentProgress * availableWidth
            
            ZStack(alignment: .leading) {
                // Track background - clickable
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 6)
                    .contentShape(Capsule())
                    .onTapGesture { location in
                        let newProgress = (location.x - thumbWidth / 2) / availableWidth
                        let clampedProgress = max(0, min(1, newProgress))
                        progress = clampedProgress
                    }
                
                // Glowing thumb - draggable
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbWidth, height: isDragging ? 8 : 6)
                    .shadow(color: Color.orange.opacity(0.9), radius: isDragging ? 10 : 6, x: 0, y: 0)
                    .shadow(color: Color.orange.opacity(0.6), radius: isDragging ? 16 : 12, x: 0, y: 0)
                    .offset(x: thumbOffset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let newProgress = (value.location.x - thumbWidth / 2) / availableWidth
                                dragProgress = max(0, min(1, newProgress))
                                progress = dragProgress
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                    .animation(.easeOut(duration: 0.1), value: isDragging)
            }
            .onAppear {
                self.trackWidth = trackWidth
            }
        }
        .frame(height: 10)
        .contentShape(Rectangle())
    }
}
