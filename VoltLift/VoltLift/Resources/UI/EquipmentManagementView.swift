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
        var equipment = self.userPreferencesService.selectedEquipment

        // Filter by category
        if self.selectedCategory != "All" {
            equipment = equipment.filter { $0.category == self.selectedCategory }
        }

        // Filter by search text
        if !self.searchText.isEmpty {
            equipment = equipment.filter {
                $0.name.localizedCaseInsensitiveContains(self.searchText) ||
                    $0.category.localizedCaseInsensitiveContains(self.searchText)
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
        self.userPreferencesService.selectedEquipment.filter(\.isSelected).count
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

                        TextField("Search equipment...", text: self.$searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignSystem.ColorRole.surface)
                    .cornerRadius(DesignSystem.Radius.m)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(self.categories, id: \.self) { category in
                                Button {
                                    self.selectedCategory = category
                                } label: {
                                    Text(category)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            self.selectedCategory == category
                                                ? DesignSystem.ColorRole.primary
                                                : DesignSystem.ColorRole.surface
                                        )
                                        .foregroundColor(
                                            self.selectedCategory == category
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
                    ForEach(self.filteredEquipment) { equipment in
                        EquipmentRow(
                            equipment: equipment,
                            isSelected: equipment.isSelected,
                            onToggle: { isSelected in
                                Task {
                                    await self.toggleEquipment(equipment, isSelected: isSelected)
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
                    if self.filteredEquipment.isEmpty, !self.searchText.isEmpty {
                        ContentUnavailableView(
                            "No Equipment Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your search or category filter")
                        )
                    } else if self.filteredEquipment.isEmpty {
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
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if self.userPreferencesService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(self.selectedCount) selected")
                            .font(.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                }
            }
            .withErrorHandling(self.userPreferencesService)
        }
    }

    // MARK: - Actions

    private func toggleEquipment(_ equipment: EquipmentItem, isSelected: Bool) async {
        do {
            try await self.userPreferencesService.updateEquipmentSelection(equipment, isSelected: isSelected)
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
                self.onToggle(!self.isSelected)
            } label: {
                Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(
                        self.isSelected
                            ? DesignSystem.ColorRole.primary
                            : DesignSystem.ColorRole.textSecondary
                    )
            }
            .buttonStyle(.plain)

            // Equipment info
            VStack(alignment: .leading, spacing: 4) {
                Text(self.equipment.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                Text(self.equipment.category)
                    .font(.caption)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
            }

            Spacer()

            // Equipment icon based on category
            Image(systemName: self.iconForCategory(self.equipment.category))
                .font(.title3)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            self.onToggle(!self.isSelected)
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "cardio":
            "heart.fill"
        case "strength", "weights":
            "dumbbell.fill"
        case "flexibility", "yoga":
            "figure.yoga"
        case "functional":
            "figure.strengthtraining.functional"
        case "accessories":
            "gear"
        default:
            "dumbbell"
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
