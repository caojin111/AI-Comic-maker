//
//  SettingsPopupView.swift
//  AI Picture Book
//
//  Settings as centered popup: left icon + right text rows.
//

import SwiftUI

struct SettingsPopupView: View {
    @Binding var isPresented: Bool
    @State private var selectedItem: SettingsView.SettingsItem?

    private func icon(for item: SettingsView.SettingsItem) -> String {
        switch item {
        case .privacy: return "lock.shield.fill"
        case .terms: return "doc.text.fill"
        case .contact: return "envelope.fill"
        }
    }

    private func iconColor(for item: SettingsView.SettingsItem) -> Color {
        switch item {
        case .privacy: return Color(hex: "4ECDC4")
        case .terms: return Color(hex: "594CE6")
        case .contact: return AppTheme.primary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(AppTheme.font(size: 20))
                    .foregroundStyle(AppTheme.textOnLight)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTheme.font(size: 28))
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
                .buttonStyle(ClickSoundButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)

            // Rows: left icon + right text
            VStack(spacing: 8) {
                ForEach(SettingsView.SettingsItem.allCases, id: \.self) { item in
                    Button(action: { selectedItem = item }) {
                        HStack(spacing: 16) {
                            Image(systemName: icon(for: item))
                                .font(AppTheme.font(size: 20))
                                .foregroundStyle(iconColor(for: item))
                                .frame(width: 44, height: 44)
                                .background(iconColor(for: item).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            Text(item.rawValue)
                                .font(AppTheme.font(size: 17))
                                .foregroundStyle(AppTheme.textOnLight)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(AppTheme.font(size: 14))
                                .foregroundStyle(Color.gray.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 340)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
        .sheet(item: $selectedItem) { item in
            SettingsDetailView(item: item)
        }
    }
}
