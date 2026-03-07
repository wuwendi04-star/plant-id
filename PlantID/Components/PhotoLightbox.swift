import SwiftUI

struct PhotoLightbox: View {
    let photo: Photo
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    private var image: UIImage? {
        guard !photo.filePath.isEmpty,
              let data = try? Data(contentsOf: URL(fileURLWithPath: photo.filePath)) else {
            return nil
        }
        return UIImage(data: data)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = max(1.0, value.magnification)
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    scale = max(1.0, min(scale, 4.0))
                                    if scale <= 1.0 { offset = .zero }
                                }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = value.translation
                                        }
                                    }
                                    .onEnded { _ in
                                        if scale <= 1.0 {
                                            withAnimation(.spring()) { offset = .zero }
                                        }
                                    }
                            )
                    )
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Overlay: top bar
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .padding(16)
                    }
                    Spacer()
                }

                Spacer()

                if !photo.note.isEmpty || true {
                    bottomBar
                }
            }
        }
        .ignoresSafeArea()
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(photo.takenAt.formattedYMD)
                .font(AppFonts.caption())
                .foregroundStyle(.white.opacity(0.7))
            if !photo.note.isEmpty {
                Text(photo.note)
                    .font(AppFonts.body())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
