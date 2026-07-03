import SwiftUI

// 升级成功弹窗
struct LevelUpView: View {
    let newLevel: Int
    let unlockedFeatures: [UnlockableFeature]
    @Environment(\.dismiss) private var dismiss
    @State private var animateScale = false
    @State private var animateOpacity = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 24) {
                // 升级标题
                VStack(spacing: 12) {
                    Text("🎉")
                        .font(.system(size: 80))
                        .scaleEffect(animateScale ? 1.0 : 0.5)
                        .opacity(animateOpacity ? 1 : 0)
                    
                    Text("升级成功！")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.blue)
                        Text("LV \(newLevel)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                // 解锁功能列表
                if !unlockedFeatures.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("解锁新能力")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ForEach(unlockedFeatures, id: \.self) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: feature.icon)
                                    .font(.title3)
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.rawValue)
                                        .font(.headline)
                                    Text(feature.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                    }
                }
                
                // 确认按钮
                Button {
                    dismiss()
                } label: {
                    Text("太棒了！")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            // 触发振动反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // 动画
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateScale = true
            }
            withAnimation(.easeIn(duration: 0.3)) {
                animateOpacity = true
            }
        }
    }
}

// 锁定功能提示视图
struct LockedFeatureOverlay: View {
    let feature: UnlockableFeature
    let currentLevel: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(feature.rawValue)
                .font(.headline)
            
            Text("需要 LV \(feature.requiredLevel) 解锁")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            let levelsNeeded = feature.requiredLevel - currentLevel
            if levelsNeeded > 0 {
                Text("还需升 \(levelsNeeded) 级")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
            }
            
            Button {
                onDismiss()
            } label: {
                Text("我知道了")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue))
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
        .padding(.horizontal, 40)
    }
}

