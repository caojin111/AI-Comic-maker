//
//  LoadingScreenView.swift
//  AI Comic maker
//
//  生成漫画的 Loading 屏幕

import SwiftUI
import Lottie

struct LoadingScreenView: View {
    @State var currentPage: Int = 0
    @State var totalPages: Int = 0
    @State var currentStatus: String = "Generating your story..."
    @State private var statusStep = 0

    private let playfulStatuses = [
        "Generating your story...",
        "Shaping your comic plot...",
        "Sketching scene ideas...",
        "Generating character images...",
        "Painting comic details...",
        "Compositing panels together...",
        "Polishing your final pages..."
    ]
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color(hex: "0F1419"),
                    Color(hex: "1A1F2E"),
                    Color(hex: "16213E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Lottie 动画加载指示器
                VStack(spacing: 24) {
                    LottieView(
                        animationName: "loading",
                        subdirectory: "lottie",
                        loopMode: .loop,
                        contentMode: .scaleAspectFit
                    )
                    .frame(width: 300, height: 300)
                    
                    VStack(spacing: 8) {
                        Text("Creating Your Comic")
                            .font(AppTheme.fontRowdiesBold(size: 24))
                            .foregroundStyle(Color.white)
                        
                        Text(currentStatus)
                            .font(AppTheme.font(size: 14))
                            .foregroundStyle(Color(hex: "B0B0B0"))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // 进度信息
                if totalPages > 0 {
                    VStack(spacing: 16) {
                        // 进度条（真实进度）
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "1A1F2E"))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF1493"), Color(hex: "00D9FF")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: CGFloat(currentPage) / CGFloat(totalPages) * 300, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                        .frame(maxWidth: 300)
                        
                        // 进度文本
                        HStack(spacing: 8) {
                            Text("Image Generation Progress")
                                .font(AppTheme.fontBold(size: 13))
                                .foregroundStyle(Color(hex: "00D9FF"))
                            
                            Spacer()
                            
                            Text("\(currentPage)/\(totalPages)")
                                .font(AppTheme.fontBold(size: 13))
                                .foregroundStyle(Color(hex: "FF1493"))
                        }
                        .frame(maxWidth: 300)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            startStatusCycling()
        }
    }

    private func startStatusCycling() {
        Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { timer in
            statusStep += 1
            withAnimation(.easeInOut(duration: 0.35)) {
                currentStatus = playfulStatuses[statusStep % playfulStatuses.count]
            }
            if totalPages > 0, currentPage >= totalPages {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    LoadingScreenView()
}

