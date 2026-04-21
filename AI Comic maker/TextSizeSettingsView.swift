//
//  TextSizeSettingsView.swift
//  AI Comic maker
//
//  文本大小设置弹窗：滑动条调整字体大小
//

import SwiftUI

struct TextSizeSettingsView: View {
    @Binding var textSize: Double // 0.0 = 最小，1.0 = 最大
    @Binding var isPresented: Bool
    
    private var fontSize: CGFloat {
        let minSize: CGFloat = 14
        let maxSize: CGFloat = 28
        return minSize + (maxSize - minSize) * CGFloat(textSize)
    }
    
    var body: some View {
        ZStack {
            // 遮罩层（淡入动画）
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
                .opacity(isPresented ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: isPresented)
            
            // 滑动条容器
            VStack(spacing: 24) {
                Text("Text Size")
                    .font(AppTheme.font(size: 20))
                    .foregroundStyle(.white)
                
                // 滑动条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // 背景轨道
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 6)
                        
                        // 进度轨道
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * CGFloat(textSize), height: 6)
                        
                        // 滑块
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .offset(x: geo.size.width * CGFloat(textSize) - 12)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let newValue = max(0, min(1, value.location.x / geo.size.width))
                                        withAnimation(.linear(duration: 0.1)) {
                                            textSize = Double(newValue)
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 20)
                
                // 预览文本
                Text("Preview text size")
                    .font(AppTheme.font(size: fontSize))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.7))
            )
            .scaleEffect(isPresented ? 1 : 0.9)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        }
    }
}

#Preview {
    TextSizeSettingsView(textSize: .constant(0.5), isPresented: .constant(true))
}
