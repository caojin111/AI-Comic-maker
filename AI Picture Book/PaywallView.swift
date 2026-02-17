//
//  PaywallView.swift
//  AI Picture Book
//
//  Subscription paywall: 3 plans, close button. Close or complete subscription -> home.
//

import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var appState

    private let plans: [(title: String, price: String, period: String)] = [
        ("Monthly", "$4.99", "/ month"),
        ("Yearly", "$29.99", "/ year"),
        ("Lifetime", "$59.99", " one-time")
    ]

    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: {
                        appState.dismissPaywall()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                Spacer()

                Text("Unlock unlimited stories")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Choose the plan that works for you")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    ForEach(Array(plans.enumerated()), id: \.offset) { _, plan in
                        Button(action: {
                            appState.dismissPaywall()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.title)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(AppTheme.textOnLight)
                                    Text(plan.period)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.gray)
                                }
                                Spacer()
                                Text(plan.price)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(AppTheme.primary)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

#Preview {
    PaywallView()
        .environment(AppState.shared)
}
