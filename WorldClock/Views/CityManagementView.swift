import SwiftUI

/// View for managing cities (add/remove)
struct CityManagementView: View {
    @ObservedObject var viewModel: WorldClockViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var filteredPresets: [City] {
        if searchText.isEmpty {
            return City.presets.filter { preset in
                !viewModel.cities.contains { $0.name == preset.name }
            }
        }
        return City.presets.filter { city in
            !viewModel.cities.contains { $0.name == city.name } &&
            (city.name.localizedCaseInsensitiveContains(searchText) ||
             city.localizedName.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("管理城市")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Current cities section
            VStack(alignment: .leading, spacing: 8) {
                Text("当前城市")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                if viewModel.cities.isEmpty {
                    Text("暂无城市，请添加")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.cities) { city in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.localizedName)
                                        .font(.body)
                                    Text(city.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(city.formattedTime())
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    withAnimation {
                                        viewModel.removeCity(city)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                        .onMove(perform: viewModel.moveCity)
                    }
                    .listStyle(.inset)
                    .frame(height: min(CGFloat(viewModel.cities.count) * 50 + 20, 200))
                }
            }
            
            Divider()
                .padding(.top, 8)
            
            // Add cities section
            VStack(alignment: .leading, spacing: 8) {
                Text("添加城市")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜索城市...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Available cities list
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredPresets) { city in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.localizedName)
                                        .font(.body)
                                    Text("\(city.name) • \(city.timeZoneIdentifier)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        viewModel.addCity(city)
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.05))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Spacer()
        }
        .frame(width: 400, height: 600)
    }
}

#Preview {
    CityManagementView(viewModel: WorldClockViewModel())
}
