//
//  EquipmentManagementView.swift
//  VoltLift
//
//  Created by Kiro on 15.9.2025.
//

import SwiftUI

struct EquipmentManagementView: View {
    @ObservedObject var userPreferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    private var categories: [String] {
        let allCategories = Set(userPreferencesService.selectedEquipment.map(\.category))
        return ["All"] + Array(allCategories).sorted()
    }
    
    private var filteredEquipment: [EquipmentItem] {
        var equipment = userPreferencesService.selectedEquipment
        
        // Filter by category
        if selectedCategory != "All" {
            equipment = equipment.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            equipment = equipment.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return equipment.sorted { first, second in
            // Sort selected items first, then by name
            if first.isSelected != second.isSelected {
                return first.isSelected && !second.isSelected
            }
            return first.name < second.name
        }
    }
    
    private var selectedCount: Int {
        userPreferencesService.selectedEquipment.filter(\.isSelected).count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filter section
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        
                        TextField("Search equipment...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignSystem.ColorRole.surface)
                    .cornerRadius(DesignSystem.Radius.m)
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Text(category)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedCategory == category 
                                                ? DesignSystem.ColorRole.primary
                                                : DesignSystem.ColorRole.surface
                                        )
                                        .foregroundColor(
                                            selectedCategory == category
                                                ? .white
                                                : DesignSystem.ColorRole.textPrimary
                                        )
                                        .cornerRadius(DesignSystem.Radius.s)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
                .background(DesignSystem.ColorRole.background)
                
                // Equipment list
                List {
                    ForEach(filteredEquipment) { equipment in
                        EquipmentRow(
                            equipment: equipment,
                            isSelected: equipment.isSelected,
                            onToggle: { isSelected in
                                Task {
                                    await toggleEquipment(equipment, isSelected: isSelected)
                                }
                            }
                        )
                        .listRowBackground(DesignSystem.ColorRole.surface)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .background(DesignSystem.ColorRole.background)
                .overlay {
                    if filteredEquipment.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView(
                            "No Equipment Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your search or category filter")
                        )
                    } else if filteredEquipment.isEmpty {
                        ContentUnavailableView(
                            "No Equipment Available",
                            systemImage: "dumbbell",
                            description: Text("Equipment data will appear here once loaded")
                        )
                    }
                }
            }
            .navigationTitle("Equipment Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if userPreferencesService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(selectedCount) selected")
                            .font(.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                }
            }
            .withErrorHandling(userPreferencesService)
        }
    }
    
    // MARK: - Actions
    
    private func toggleEquipment(_ equipment: EquipmentItem, isSelected: Bool) async {
        do {
            try await userPreferencesService.updateEquipmentSelection(equipment, isSelected: isSelected)
        } catch {
            // Error handling is managed by the UserPreferencesService and withErrorHandling modifier
            print("Failed to update equipment selection: \(error)")
        }
    }
}

// MARK: - Equipment Row

struct EquipmentRow: View {
    let equipment: EquipmentItem
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Button {
                onToggle(!isSelected)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(
                        isSelected 
                            ? DesignSystem.ColorRole.primary
                            : DesignSystem.ColorRole.textSecondary
                    )
            }
            .buttonStyle(.plain)
            
            // Equipment info
            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                
                Text(equipment.category)
                    .font(.caption)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
            }
            
            Spacer()
            
            // Equipment icon based on category
            Image(systemName: iconForCategory(equipment.category))
                .font(.title3)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle(!isSelected)
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "cardio":
            return "heart.fill"
        case "strength", "weights":
            return "dumbbell.fill"
        case "flexibility", "yoga":
            return "figure.yoga"
        case "functional":
            return "figure.strengthtraining.functional"
        case "accessories":
            return "gear"
        default:
            return "dumbbell"
        }
    }
}

// MARK: - Preview

#Preview {
    EquipmentManagementView(
        userPreferencesService: {
            let service = UserPreferencesService()
            service.selectedEquipment = [
                EquipmentItem(id: "1", name: "Barbell", category: "Strength", isSelected: true),
                EquipmentItem(id: "2", name: "Dumbbells", category: "Strength", isSelected: true),
                EquipmentItem(id: "3", name: "Treadmill", category: "Cardio", isSelected: false),
                EquipmentItem(id: "4", name: "Yoga Mat", category: "Flexibility", isSelected: false)
            ]
            return service
        }()
    )
}