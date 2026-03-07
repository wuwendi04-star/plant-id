import SwiftUI
import SwiftData

struct NfcScanView: View {
    @Environment(AppRouter.self) private var router
    @Environment(NfcService.self) private var nfcService
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: NfcScanViewModel?
    @State private var pulse1 = false
    @State private var pulse2 = false
    @State private var pulse3 = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            BackgroundGradientView()
            VStack(spacing: 32) {
                Text("Scan NFC Tag")
                    .font(AppFonts.title())
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, 40)

                nfcAnimation

                statusText

                actionButtons

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(false)
        .onAppear {
            if viewModel == nil {
                viewModel = NfcScanViewModel(
                    plantRepo: SwiftDataPlantRepository(modelContext: modelContext)
                )
            }
            viewModel?.setCreateMode(true)
            viewModel?.loadBoundTags()
            startAnimation()
        }
        .onChange(of: viewModel?.navEvent) { _, event in
            handleNavEvent(event)
        }
    }

    private var nfcAnimation: some View {
        ZStack {
            pulsingRing(scale: pulse1 ? 1.8 : 1.0, opacity: pulse1 ? 0 : 0.3, delay: 0)
            pulsingRing(scale: pulse2 ? 1.5 : 1.0, opacity: pulse2 ? 0 : 0.5, delay: 0.3)
            pulsingRing(scale: pulse3 ? 1.2 : 1.0, opacity: pulse3 ? 0 : 0.7, delay: 0.6)
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.textPrimary)
                        .rotationEffect(.degrees(rotation))
                )
                .cardStyle()
        }
        .frame(width: 200, height: 200)
    }

    private func pulsingRing(scale: CGFloat, opacity: Double, delay: Double) -> some View {
        Circle()
            .stroke(AppColors.textPrimary, lineWidth: 2)
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
            .opacity(opacity)
    }

    private var statusText: some View {
        Group {
            if !nfcService.isAvailable {
                Text("NFC not available on this device")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.urgencyOverdue)
                    .multilineTextAlignment(.center)
            } else if nfcService.isScanning {
                Text("Scanning…")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                Text("Hold your iPhone near an NFC tag\nor skip to create without one")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if nfcService.isAvailable {
                Button("Scan NFC Tag") {
                    nfcService.startScanning { tagId in
                        viewModel?.processTag(tagId)
                    }
                }
                .primaryButtonStyle()
                .disabled(nfcService.isScanning)
            }

            Button("Create without NFC") {
                router.navigateToCreatePlant(nfcTagId: nil)
            }
            .font(AppFonts.body())
            .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulse1 = true
        }
        withAnimation(.easeInOut(duration: 1.5).delay(0.3).repeatForever(autoreverses: true)) {
            pulse2 = true
        }
        withAnimation(.easeInOut(duration: 1.5).delay(0.6).repeatForever(autoreverses: true)) {
            pulse3 = true
        }
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    private func handleNavEvent(_ event: NfcNavEvent?) {
        switch event {
        case .goToDetail(let id):
            viewModel?.consumeNavEvent()
            router.pop()
            router.navigateToPlantDetail(id)
        case .goToCreate(let tagId):
            viewModel?.consumeNavEvent()
            router.navigateToCreatePlant(nfcTagId: tagId)
        case .tagOrphaned:
            viewModel?.consumeNavEvent()
        case .none, nil:
            break
        }
    }
}
