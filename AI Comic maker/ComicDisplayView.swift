import SwiftUI
import Photos
import UIKit
import PhotosUI
import CoreText
import Mixpanel

struct ComicDisplayView: View {
    static let textOverlayBaseFontSize: CGFloat = 26
    static let textOverlayHorizontalPadding: CGFloat = 18
    static let textOverlayVerticalPadding: CGFloat = 10
    static let textOverlayCornerRadius: CGFloat = 16
    private static let canvasHorizontalPadding: CGFloat = 60
    private static let canvasVerticalPadding: CGFloat = 20
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var appOB: AppObservableObject
    @State private var currentPageIndex = 0
    @State private var comicPages: [ComicPage] = []
    @State private var storyTitle: String = ""
    @State private var saveState: SaveState = .idle
    @State private var regenerateState: RegenerateState = .idle
    @State private var fishCoinManager = FishCoinManager.shared
    @State private var isEditMode = false
    @State private var pendingTextInput = ""
    @State private var isEditingSelectedText = false
    @State private var selectedOverlayId: UUID?
    @State private var pageOverlays: [UUID: [ComicOverlayItem]] = [:]
    @State private var imagePickerItem: PhotosPickerItem?
    @State private var isLoadingOverlayImage = false
    @State private var editSurfaceImageAspect: CGFloat = 1
    @State private var matMagnifyStartScale: CGFloat?
    @State private var baseImageOffset: CGSize = .zero
    @State private var baseImageDragStartOffset: CGSize?
    @State private var exportTextScale: CGFloat = 1
    @State private var previewCanvasSizeForExport: CGSize = .zero
    @State private var previewScaledCanvasSizeForExport: CGSize = .zero

    enum SaveState {
        case idle, saving, success, denied
    }
    
    enum RegenerateState {
        case idle, regenerating, success, failed
    }

    let story: SavedStory?
    private let displayedStoryId: UUID?

    init(isPresented: Binding<Bool>, story: SavedStory? = nil) {
        self._isPresented = isPresented
        self.story = story

        let storyToDisplay = story ?? AppState.shared.viewingSavedStory
        self.displayedStoryId = storyToDisplay?.id

        if let storyToDisplay = storyToDisplay {
            print("[ComicDisplayView] 初始化显示故事，storyId: \(storyToDisplay.id), theme: \(storyToDisplay.theme), pages: \(storyToDisplay.pages.count)")
            self._comicPages = State(initialValue: storyToDisplay.pages.map { page in
                ComicPage(id: page.id, imageUrl: page.imageUrl, title: page.text, localFilename: page.localImagePath, imagePrompt: page.imagePrompt, hasRegeneratedImage: page.hasRegeneratedImage, isEditableCopy: page.isEditableCopy)
            })
            self._storyTitle = State(initialValue: storyToDisplay.theme)
        } else {
            print("[ComicDisplayView] 初始化时未找到可显示的故事，story 参数与 viewingSavedStory 均为空")
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0F1419"), Color(hex: "1A1F2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { isPresented = false }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(AppTheme.font(size: 16))
                            Text("Back")
                                .font(AppTheme.fontBold(size: 14))
                        }
                        .foregroundStyle(Color(hex: "FF1493"))
                    }
                    .buttonStyle(ClickSoundButtonStyle())

                    Spacer()

                    Text("Page \(currentPageIndex + 1) of \(comicPages.count)")
                        .font(AppTheme.fontBold(size: 14))
                        .foregroundStyle(Color.white)

                    Spacer()

                    Color.clear.frame(width: 44, height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(hex: "1A1F2E").opacity(0.8))

                ZStack {
                    if !comicPages.isEmpty {
                        editableCanvas
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(AppTheme.font(size: 48))
                                .foregroundStyle(Color(hex: "FF1493").opacity(0.5))
                            Text("No Comic Data")
                                .font(AppTheme.fontBold(size: 16))
                                .foregroundStyle(Color.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if !isEditMode {
                        pageNavigationButtons
                    }
                }
                .frame(maxHeight: .infinity)

                bottomActionArea
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
            }
        }
        .onAppear {
            setOrientation(.portrait)
            refreshEditSurfaceImageAspect()
        }
        .onChange(of: isEditMode) { _, isOn in
            if isOn {
                refreshEditSurfaceImageAspect()
            }
        }
        .onChange(of: currentPageIndex) { _, _ in
            saveState = .idle
            regenerateState = .idle
            selectedOverlayId = nil
            pendingTextInput = ""
            isEditingSelectedText = false
            imagePickerItem = nil
            matMagnifyStartScale = nil
            baseImageOffset = .zero
            baseImageDragStartOffset = nil
            refreshEditSurfaceImageAspect()
        }
        .onChange(of: imagePickerItem) { _, newValue in
            guard let newValue else { return }
            handlePickedImage(newValue)
        }
    }

    private var currentMatScale: CGFloat {
        guard let mat = currentOverlays.first(where: { $0.isBackgroundMatKind }),
              case .backgroundMat(_, let scale) = mat.kind else {
            return 1
        }
        return scale
    }

    private var displayCanvasAspectRatio: CGFloat {
        max(editSurfaceImageAspect, 0.01)
    }

    private var displayCanvasScale: CGFloat {
        max(currentMatScale, 1)
    }

    private var editableCanvas: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - ComicDisplayView.canvasHorizontalPadding * 2, 1)
            let availableHeight = max(geometry.size.height - ComicDisplayView.canvasVerticalPadding * 2, 1)
                        let currentPage = comicPages[currentPageIndex]
            let matScale = max(currentMatScale, 1)
            let targetCanvasSize = fittedCanvasSize(
                imageAspect: displayCanvasAspectRatio,
                containerSize: CGSize(width: availableWidth / matScale, height: availableHeight / matScale)
            )
            let scaledCanvasSize = CGSize(width: targetCanvasSize.width * matScale, height: targetCanvasSize.height * matScale)

            editableCanvasContent(
                page: currentPage,
                canvasSize: targetCanvasSize,
                contentScale: matScale,
                showsSelection: isEditMode
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, ComicDisplayView.canvasHorizontalPadding)
            .padding(.vertical, ComicDisplayView.canvasVerticalPadding)
            .onAppear {
                previewCanvasSizeForExport = targetCanvasSize
                previewScaledCanvasSizeForExport = scaledCanvasSize
                print("[ComicDisplayView] Preview canvas size captured on appear: \(targetCanvasSize), scaled: \(scaledCanvasSize)")
            }
            .onChange(of: targetCanvasSize) { _, newValue in
                previewCanvasSizeForExport = newValue
                previewScaledCanvasSizeForExport = CGSize(width: newValue.width * matScale, height: newValue.height * matScale)
                print("[ComicDisplayView] Preview canvas size updated: \(newValue), scaled: \(previewScaledCanvasSizeForExport)")
            }
        }
    }

    @ViewBuilder
    private func editableCanvasContent(page: ComicPage, canvasSize: CGSize, contentScale: CGFloat, showsSelection: Bool) -> some View {
        let scaledCanvasSize = CGSize(width: canvasSize.width * contentScale, height: canvasSize.height * contentScale)
        let baseImageRect = centeredRect(innerSize: canvasSize, outerSize: scaledCanvasSize)
            let canvasStack = ZStack {
                ForEach(currentOverlays.filter(\.isBackgroundMatKind)) { item in
                    BackgroundMatPreviewLayer(
                        item: bindingForOverlay(item.id),
                    canvasSize: scaledCanvasSize,
                    imageRect: baseImageRect,
                    isSelected: showsSelection && selectedOverlayId == item.id
                    )
                }

            currentPageBaseView(page: page)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .position(x: baseImageRect.midX + baseImageOffset.width, y: baseImageRect.midY + baseImageOffset.height)
                .contentShape(Rectangle())
                .gesture(baseImageDragGesture(enabled: isEditMode && isBackgroundMatSelected))

                ForEach(currentOverlays.filter { !$0.isBackgroundMatKind }) { item in
                    EditableOverlayView(
                        item: bindingForOverlay(item.id),
                    canvasSize: scaledCanvasSize,
                    imageRect: CGRect(origin: .zero, size: scaledCanvasSize),
                        blockPinchRotate: isBackgroundMatSelected,
                        onSelect: {
                            guard isEditMode else { return }
                            selectedOverlayId = item.id
                            print("[ComicDisplayView] Selected editable item, overlayId: \(item.id)")
                        },
                        onDoubleTapText: {
                            guard isEditMode else { return }
                            selectedOverlayId = item.id
                        if case .text(let content, _, _) = item.kind {
                                pendingTextInput = content
                                isEditingSelectedText = true
                            }
                        }
                    )
                .allowsHitTesting(isEditMode)
                }

            if isLoadingOverlayImage && showsSelection {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.55))
                        VStack(spacing: 10) {
                            ProgressView()
                                .tint(.white)
                            Text("Loading image...")
                                .font(AppTheme.fontBold(size: 14))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                    }
                    .frame(width: 160, height: 100)
                }
            }
        .frame(width: scaledCanvasSize.width, height: scaledCanvasSize.height)
            .background(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditMode {
                    selectedOverlayId = nil
                }
            }
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        guard isEditMode, isBackgroundMatSelected else { return }
                        applyBackgroundMatMagnify(gestureMagnification: value.magnification)
                    }
                    .onEnded { _ in
                        matMagnifyStartScale = nil
                        print("[ComicDisplayView] Background mat pinch ended")
                    }
            )

            canvasStack
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black, lineWidth: 3)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "FF1493"), lineWidth: 1.5)
                                )
    }

    @ViewBuilder
    private func currentPageBaseView(page: ComicPage) -> some View {
        if let image = previewUIImage(for: page) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(Color(hex: "FF1493"))
                if !currentImagePlaceholderText.isEmpty {
                                    Text(currentImagePlaceholderText)
                                        .font(AppTheme.font(size: 14))
                                        .foregroundStyle(Color(hex: "B0B0B0"))
                }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(hex: "1A1F2E"))
                            }
    }

    private func previewUIImage(for page: ComicPage) -> UIImage? {
        if let filename = page.localFilename,
           let image = ImageCache.shared.loadPersistent(filename: filename) {
            return image
        }
        guard !page.imageUrl.isEmpty,
              let url = URL(string: page.imageUrl) else {
            return nil
        }
        return ImageCache.shared.loadCachedOnly(url: url)
    }

    private func baseImageDragGesture(enabled: Bool) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard enabled else { return }
                if baseImageDragStartOffset == nil {
                    baseImageDragStartOffset = baseImageOffset
                    print("[ComicDisplayView] Start dragging base image, initialOffset: \(baseImageOffset)")
                }
                let start = baseImageDragStartOffset ?? baseImageOffset
                baseImageOffset = CGSize(
                    width: start.width + value.translation.width,
                    height: start.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard enabled else { return }
                print("[ComicDisplayView] Finish dragging base image, finalOffset: \(baseImageOffset)")
                baseImageDragStartOffset = nil
        }
    }

    private var pageNavigationButtons: some View {
                    HStack {
                        Button(action: {
                            if currentPageIndex > 0 { currentPageIndex -= 1 }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(currentPageIndex > 0 ? Color.white : Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(currentPageIndex > 0
                                            ? Color(hex: "FF1493").opacity(0.85)
                                            : Color.white.opacity(0.08))
                                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .disabled(currentPageIndex == 0)
                        .padding(.leading, 8)

                        Spacer()

                        Button(action: {
                            if currentPageIndex < comicPages.count - 1 { currentPageIndex += 1 }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(currentPageIndex < comicPages.count - 1 ? Color.white : Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(currentPageIndex < comicPages.count - 1
                                            ? Color(hex: "FF1493").opacity(0.85)
                                            : Color.white.opacity(0.08))
                                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                        .disabled(currentPageIndex == comicPages.count - 1)
                        .padding(.trailing, 8)
                    }
                }

    private var bottomActionArea: some View {
                VStack(spacing: 12) {
            if isEditMode {
                if let selectedOverlay = selectedOverlay {
                    if case .text = selectedOverlay.kind, isEditingSelectedText {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Text input")
                                .font(AppTheme.fontBold(size: 13))
                                .foregroundStyle(Color.white.opacity(0.85))
                            HStack(spacing: 10) {
                                TextField("Type something...", text: $pendingTextInput)
                                    .font(AppTheme.font(size: 15))
                                    .padding(.horizontal, 16)
                                    .frame(height: 46)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.white.opacity(0.12))
                                    )
                                    .foregroundStyle(.white)
                                Button(action: confirmTextInput) {
                                    Text("Done")
                                        .font(AppTheme.fontBold(size: 14))
                                        .foregroundStyle(.white)
                                        .frame(width: 82, height: 46)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(Color(hex: "FF1493"))
                                        )
                                }
                                .buttonStyle(ClickSoundButtonStyle())
                            }
                        }
                    }

                    if case .backgroundMat(let isWhite, _) = selectedOverlay.kind {
                        HStack(spacing: 10) {
                            Button(action: toggleBackgroundMatColor) {
                                editToolButton(icon: isWhite ? "circle.lefthalf.filled.inverse" : "circle.lefthalf.filled")
                            }
                            .buttonStyle(ClickSoundButtonStyle())

                            Button(action: finishBackgroundMatEditing) {
                                editToolButton(title: "Done", icon: "checkmark.circle")
                            }
                            .buttonStyle(ClickSoundButtonStyle())
                        }
                    }

                    HStack(spacing: 10) {
                        Button(action: deleteSelectedOverlay) {
                            editToolButton(title: "Delete", icon: "trash")
                        }
                        .buttonStyle(ClickSoundButtonStyle())
                    }
                }

        HStack {
            Button(action: {
                selectedOverlayId = nil
                pendingTextInput = ""
                isEditingSelectedText = false
                isEditMode = false
                baseImageDragStartOffset = nil
                print("[ComicDisplayView] Exit edit mode, keep overlays and base image background, pageId: \(comicPages[currentPageIndex].id), baseImageOffset: \(baseImageOffset)")
                AnalyticsManager.track(
                    AnalyticsEvent.imageEditCompleted,
                    properties: [
                        "page_id": comicPages[currentPageIndex].id.uuidString,
                        "story_id": displayedStoryId?.uuidString ?? "",
                        "page_index": currentPageIndex + 1,
                        "overlay_count": currentOverlays.count,
                        "has_background_mat": currentOverlays.contains(where: { $0.isBackgroundMatKind })
                    ]
                )
            }) {
                editToolButton(title: "Done", icon: "checkmark.circle")
            }
            .buttonStyle(ClickSoundButtonStyle())

            Button(action: addTextOverlay) {
                iconOnlyEditToolButton(icon: "textformat")
            }
            .buttonStyle(ClickSoundButtonStyle())

            PhotosPicker(selection: $imagePickerItem, matching: .images, photoLibrary: .shared()) {
                iconOnlyEditToolButton(icon: "photo.badge.plus")
            }
            .buttonStyle(ClickSoundButtonStyle())

            Button(action: addBackgroundMatOverlay) {
                iconOnlyEditToolButton(icon: "rectangle.inset.filled")
            }
            .buttonStyle(ClickSoundButtonStyle())
                            }
            } else {
                Button(action: saveCurrentImage) {
                    editPrimaryButton(title: saveButtonLabel, icon: saveButtonIcon, color: saveButtonColor)
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .disabled(saveState == .saving || saveState == .success || comicPages.isEmpty || regenerateState == .regenerating)

                    Button(action: regenerateCurrentImage) {
                        HStack(spacing: 10) {
                            if regenerateState == .regenerating {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.85)
                            } else if regenerateState == .success {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                            } else if regenerateState == .failed {
                                Image(systemName: "exclamationmark")
                                    .font(.system(size: 15, weight: .bold))
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 15, weight: .semibold))
                            }

                            if regenerateState == .idle {
                                HStack(spacing: 6) {
                                    Text("Regenerate")
                                        .font(AppTheme.fontBold(size: 16))
                                    Image("fish coin")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                    Text("x5")
                                        .font(AppTheme.fontBold(size: 15))
                                }
                            } else {
                                Text(regenerateButtonLabel)
                                    .font(AppTheme.fontBold(size: 16))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(regenerateButtonColor)
                                .shadow(color: regenerateButtonColor.opacity(0.45), radius: 10, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(ClickSoundButtonStyle())
                    .disabled(regenerateButtonDisabled)

                Button(action: enterEditMode) {
                    editToolButton(title: "Edit", icon: "slider.horizontal.3")
                }
                .buttonStyle(ClickSoundButtonStyle())
                .disabled(comicPages.isEmpty || regenerateState == .regenerating || saveState == .saving)
            }
        }
    }

    private func editPrimaryButton(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            if saveState == .saving {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.85)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
            }
            Text(title)
                .font(AppTheme.fontBold(size: 16))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(color)
                .shadow(color: color.opacity(0.45), radius: 10, x: 0, y: 4)
        )
    }

    private func editToolButton(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(AppTheme.fontBold(size: 15))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func editToolButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }

    private func iconOnlyEditToolButton(icon: String) -> some View {
        editToolButton(icon: icon)
    }

    private var currentImagePlaceholderText: String {
        if previewUIImage(for: comicPages[currentPageIndex]) != nil {
            return ""
        }
        return regenerateState == .regenerating ? "Regenerating..." : "Loading..."
    }

    private var saveButtonLabel: String {
        switch saveState {
        case .idle:    return "Save to Photos"
        case .saving:  return "Saving..."
        case .success: return "Saved!"
        case .denied:  return "Permission Denied"
        }
    }

    private var saveButtonIcon: String {
        switch saveState {
        case .success:
            return "checkmark"
        case .denied:
            return "xmark"
        default:
            return "square.and.arrow.down"
        }
    }

    private var regenerateButtonLabel: String {
        if comicPages.isEmpty {
            return "Regenerate"
        }
        if comicPages[currentPageIndex].hasRegeneratedImage || comicPages[currentPageIndex].isEditableCopy {
            return "Already Regenerated"
        }
        switch regenerateState {
        case .idle:
            return "Regenerate"
        case .regenerating:
            return "Regenerating..."
        case .success:
            return "Regenerated!"
        case .failed:
            return "Unavailable"
        }
    }

    private var saveButtonColor: Color {
        switch saveState {
        case .success: return Color(hex: "00C896")
        case .denied:  return Color(hex: "FF4444")
        default:       return Color(hex: "FF1493")
        }
    }

    private var regenerateButtonColor: Color {
        if !comicPages.isEmpty && (comicPages[currentPageIndex].hasRegeneratedImage || comicPages[currentPageIndex].isEditableCopy) {
            return Color(hex: "505050")
        }
        switch regenerateState {
        case .success: return Color(hex: "00C896")
        case .failed:  return Color(hex: "FF4444")
        default:       return Color(hex: "00AEEF")
        }
    }

    private var regenerateButtonDisabled: Bool {
        comicPages.isEmpty
            || regenerateState == .regenerating
            || saveState == .saving
            || comicPages[currentPageIndex].hasRegeneratedImage
            || comicPages[currentPageIndex].isEditableCopy
    }

    private var currentOverlays: [ComicOverlayItem] {
        let pageId = comicPages[currentPageIndex].id
        return pageOverlays[pageId] ?? []
    }

    private var selectedOverlay: ComicOverlayItem? {
        guard let selectedOverlayId else { return nil }
        return currentOverlays.first(where: { $0.id == selectedOverlayId })
    }

    private var isBackgroundMatSelected: Bool {
        guard let selectedOverlay else { return false }
        return selectedOverlay.isBackgroundMatKind
    }

    private func bindingForOverlay(_ overlayId: UUID) -> Binding<ComicOverlayItem> {
        Binding {
            let pageId = comicPages[currentPageIndex].id
            guard let index = pageOverlays[pageId]?.firstIndex(where: { $0.id == overlayId }),
                  let item = pageOverlays[pageId]?[index] else {
                return ComicOverlayItem.text(content: "", center: .zero)
            }
            return item
        } set: { newValue in
            let pageId = comicPages[currentPageIndex].id
            guard let index = pageOverlays[pageId]?.firstIndex(where: { $0.id == overlayId }) else { return }
            pageOverlays[pageId]?[index] = newValue
        }
    }

    private func enterEditMode() {
        guard !comicPages.isEmpty else { return }
        let pageId = comicPages[currentPageIndex].id
        print("[ComicDisplayView] Enter edit mode, pageId: \(pageId)")
        AnalyticsManager.track(
            AnalyticsEvent.imageEditEntered,
            properties: [
                "page_id": pageId.uuidString,
                "story_id": displayedStoryId?.uuidString ?? "",
                "page_index": currentPageIndex + 1
            ]
        )
        if pageOverlays[pageId] == nil {
            pageOverlays[pageId] = []
        }
        regenerateState = .idle
        isEditMode = true
        selectedOverlayId = nil
        pendingTextInput = ""
    }

    private func addTextOverlay() {
        guard !comicPages.isEmpty else { return }
        let pageId = comicPages[currentPageIndex].id
        let newItem = ComicOverlayItem.text(content: "Double tap to edit", center: CGPoint(x: 0.5, y: 0.5), textColorHex: "000000", showsBackground: false)
        pageOverlays[pageId, default: []].append(newItem)
        selectedOverlayId = newItem.id
        pendingTextInput = newItem.displayText
        isEditingSelectedText = true
        AnalyticsManager.track(
            AnalyticsEvent.textOverlayAdded,
            properties: [
                "page_id": pageId.uuidString,
                "story_id": displayedStoryId?.uuidString ?? "",
                "page_index": currentPageIndex + 1
            ]
        )
        print("[ComicDisplayView] Added text overlay, overlayId: \(newItem.id), pageId: \(pageId)")
    }

    private func confirmTextInput() {
        guard let selectedOverlayId,
              let selectedOverlay,
              case .text = selectedOverlay.kind else { return }
        let text = pendingTextInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let pageId = comicPages[currentPageIndex].id
        guard let index = pageOverlays[pageId]?.firstIndex(where: { $0.id == selectedOverlayId }) else { return }
        pageOverlays[pageId]?[index].kind = .text(content: text, textColorHex: "000000", showsBackground: false)
        pageOverlays[pageId]?[index].textBoxSize = ComicOverlayItem.measureTextBoxSize(
            for: text,
            scale: pageOverlays[pageId]?[index].scale ?? 1
        )
        isEditingSelectedText = false
        print("[ComicDisplayView] Text confirmed, overlayId: \(selectedOverlayId), textLength: \(text.count)")
    }

    private func deleteSelectedOverlay() {
        guard let selectedOverlayId else { return }
        let pageId = comicPages[currentPageIndex].id
        pageOverlays[pageId]?.removeAll { $0.id == selectedOverlayId }
        self.selectedOverlayId = nil
        pendingTextInput = ""
        isEditingSelectedText = false
    }

    private func refreshEditSurfaceImageAspect() {
        guard !comicPages.isEmpty else { return }
        let page = comicPages[currentPageIndex]
        Task {
            let img = await loadUIImage(for: page)
            let aspect = img.map { $0.size.width / max($0.size.height, 1) } ?? 1
            await MainActor.run {
                editSurfaceImageAspect = max(aspect, 0.01)
                print("[ComicDisplayView] Edit surface image aspect updated to \(editSurfaceImageAspect), pageId: \(page.id)")
            }
        }
    }

    private func addBackgroundMatOverlay() {
        guard !comicPages.isEmpty else { return }
        let pageId = comicPages[currentPageIndex].id
        if let existing = pageOverlays[pageId]?.first(where: { $0.isBackgroundMatKind }) {
            selectedOverlayId = existing.id
            pendingTextInput = ""
            isEditingSelectedText = false
            print("[ComicDisplayView] Background mat already exists, selected overlayId: \(existing.id)")
            return
        }
        let newItem = ComicOverlayItem.backgroundMat(isWhite: true, matScale: 1.1, center: CGPoint(x: 0.5, y: 0.5))
        pageOverlays[pageId, default: []].append(newItem)
        selectedOverlayId = newItem.id
        pendingTextInput = ""
        isEditingSelectedText = false
        AnalyticsManager.track(
            AnalyticsEvent.backgroundAdded,
            properties: [
                "page_id": pageId.uuidString,
                "story_id": displayedStoryId?.uuidString ?? "",
                "page_index": currentPageIndex + 1,
                "default_color": "white"
            ]
        )
        print("[ComicDisplayView] Added background mat overlayId: \(newItem.id), default color=white, matScale=1.1")
    }

    private func setBackgroundMatColor(isWhite: Bool) {
        guard let selectedOverlayId,
              !comicPages.isEmpty else { return }
        let pageId = comicPages[currentPageIndex].id
        guard var list = pageOverlays[pageId],
              let idx = list.firstIndex(where: { $0.id == selectedOverlayId }),
              case .backgroundMat(_, let scale) = list[idx].kind else { return }
        list[idx].kind = .backgroundMat(isWhite: isWhite, matScale: scale)
        pageOverlays[pageId] = list
        print("[ComicDisplayView] Background mat color changed to \(isWhite ? "white" : "black"), overlayId: \(selectedOverlayId)")
    }

    private func toggleBackgroundMatColor() {
        guard let selectedOverlay,
              case .backgroundMat(let isWhite, _) = selectedOverlay.kind else { return }
        setBackgroundMatColor(isWhite: !isWhite)
    }

    private func finishBackgroundMatEditing() {
        guard let selectedOverlayId else { return }
        print("[ComicDisplayView] Finished background mat editing, overlayId: \(selectedOverlayId)")
        self.selectedOverlayId = nil
        matMagnifyStartScale = nil
    }

    private func applyBackgroundMatMagnify(gestureMagnification: CGFloat) {
        guard let selectedOverlayId,
              !comicPages.isEmpty else { return }
        let pageId = comicPages[currentPageIndex].id
        guard var list = pageOverlays[pageId],
              let idx = list.firstIndex(where: { $0.id == selectedOverlayId }),
              case .backgroundMat(let isWhite, let currentScale) = list[idx].kind else { return }
        if matMagnifyStartScale == nil {
            matMagnifyStartScale = currentScale
            print("[ComicDisplayView] Background mat pinch started, matScale: \(currentScale)")
        }
        let base = matMagnifyStartScale ?? currentScale
        let reversedMagnification = max(gestureMagnification, 0.01)
        let newScale = min(max(base / reversedMagnification, 1.02), 1.75)
        list[idx].kind = .backgroundMat(isWhite: isWhite, matScale: newScale)
        pageOverlays[pageId] = list
        print("[ComicDisplayView] Background mat pinch updated with reversed gesture, gestureMagnification: \(gestureMagnification), matScale: \(newScale)")
    }

    private func handlePickedImage(_ item: PhotosPickerItem) {
        guard !comicPages.isEmpty else { return }
        isLoadingOverlayImage = true
        print("[ComicDisplayView] Start importing edit image")
        Task {
            defer {
                Task { @MainActor in
                    isLoadingOverlayImage = false
                    imagePickerItem = nil
                }
            }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                print("[ComicDisplayView] Failed to import edit image")
                return
            }
            await MainActor.run {
                let pageId = comicPages[currentPageIndex].id
                let newItem = ComicOverlayItem.image(uiImage: uiImage, center: CGPoint(x: 0.5, y: 0.5))
                pageOverlays[pageId, default: []].append(newItem)
                selectedOverlayId = newItem.id
                pendingTextInput = ""
                AnalyticsManager.track(
                    AnalyticsEvent.imageOverlayAdded,
                    properties: [
                        "page_id": pageId.uuidString,
                        "story_id": displayedStoryId?.uuidString ?? "",
                        "page_index": currentPageIndex + 1
                    ]
                )
                print("[ComicDisplayView] Added image overlay, overlayId: \(newItem.id), pageId: \(pageId)")
            }
        }
    }

    private func saveCurrentImage() {
        guard !comicPages.isEmpty else { return }
        let page = comicPages[currentPageIndex]
        let overlaysToRender = currentOverlays
        saveState = .saving
        print("[ComicDisplayView] Save image requested, pageId: \(page.id), overlayCount: \(overlaysToRender.count), isEditMode: \(isEditMode)")

        Task {
            if overlaysToRender.isEmpty {
                print("[ComicDisplayView] No overlays found, saving original image directly")
                if let filename = page.localFilename,
                   let img = ImageCache.shared.loadPersistent(filename: filename) {
                    await saveImageToPhotoLibrary(img, pageId: page.id, overlayCount: overlaysToRender.count)
                    return
                }
                guard let url = URL(string: page.imageUrl),
                      let img = await ImageCache.shared.load(url: url) else {
                    await MainActor.run { saveState = .idle }
                    return
                }
                await saveImageToPhotoLibrary(img, pageId: page.id, overlayCount: overlaysToRender.count)
                return
            }

            print("[ComicDisplayView] Overlays detected, rendering edited image before saving to Photos")
            guard let mergedImage = await renderEditedImage(for: page, overlays: overlaysToRender) else {
                await MainActor.run {
                    print("[ComicDisplayView] Failed to render edited image for Photos save")
                    saveState = .idle
                }
                return
            }
            await saveImageToPhotoLibrary(mergedImage, pageId: page.id, overlayCount: overlaysToRender.count)
        }
    }
    
    private func regenerateCurrentImage() {
        guard !comicPages.isEmpty else { return }
        let page = comicPages[currentPageIndex]
        let pageId = page.id

        print("[ComicDisplayView] 点击 regenerate，pageId: \(pageId)")
        AnalyticsManager.track(
            AnalyticsEvent.imageRegenerationStarted,
            properties: [
                "page_id": pageId.uuidString,
                "story_id": displayedStoryId?.uuidString ?? "",
                "page_index": currentPageIndex + 1,
                "fish_coin_cost": 5
            ]
        )
        var prompt = page.imagePrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if prompt.isEmpty,
           let story {
            prompt = story.pages.first(where: { $0.id == pageId })?.imagePrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        if prompt.isEmpty,
           let currentSavedStory = appState.viewingSavedStory {
            prompt = currentSavedStory.pages.first(where: { $0.id == pageId })?.imagePrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        print("[ComicDisplayView] regenerate prompt length: \(prompt.count)")
        guard !page.hasRegeneratedImage, !page.isEditableCopy, !prompt.isEmpty else {
            print("[ComicDisplayView] regenerate 被拦截，hasRegeneratedImage=\(page.hasRegeneratedImage), isEditableCopy=\(page.isEditableCopy), promptEmpty=\(prompt.isEmpty)")
            AnalyticsManager.track(
                AnalyticsEvent.imageRegenerationFailed,
                properties: [
                    "page_id": pageId.uuidString,
                    "story_id": displayedStoryId?.uuidString ?? "",
                    "page_index": currentPageIndex + 1,
                    "reason": prompt.isEmpty ? "missing_prompt" : "already_regenerated_or_editable_copy"
                ]
            )
            regenerateState = .failed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { regenerateState = .idle }
            return
        }
        guard fishCoinManager.consumeForImageRegeneration() else {
            AnalyticsManager.track(
                AnalyticsEvent.imageRegenerationFailed,
                properties: [
                    "page_id": pageId.uuidString,
                    "story_id": displayedStoryId?.uuidString ?? "",
                    "page_index": currentPageIndex + 1,
                    "reason": "insufficient_fish_coins"
                ]
            )
            regenerateState = .failed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { regenerateState = .idle }
            return
        }
        
        regenerateState = .regenerating
        
        Task {
            let newImageUrl: String? = await withCheckedContinuation { continuation in
                ComicAPIService.shared.regenerateImage(prompt: prompt) { result in
                    switch result {
                    case .success(let resultString):
                        let resolvedImageUrl = resultString
                            .split(separator: ",")
                            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                            .first(where: { !$0.isEmpty })
                        continuation.resume(returning: resolvedImageUrl)
                    case .failure(let error):
                        print("[ComicDisplayView] regenerate failed: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                    }
                }
            }
            
            guard let newImageUrl else {
                await MainActor.run {
                    fishCoinManager.refundForImageRegeneration()
                    AnalyticsManager.track(
                        AnalyticsEvent.imageRegenerationFailed,
                        properties: [
                            "page_id": pageId.uuidString,
                            "story_id": displayedStoryId?.uuidString ?? "",
                            "page_index": currentPageIndex + 1,
                            "reason": "api_failed"
                        ]
                    )
                    regenerateState = .failed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { regenerateState = .idle }
                }
                return
            }
            
            let regeneratedPageId = UUID()
            let filename = "\(regeneratedPageId.uuidString).jpg"
            _ = await appOB.downloadAndCacheImage(pageId: regeneratedPageId, imageUrl: newImageUrl)
            
            await MainActor.run {
                guard let updatedIndex = comicPages.firstIndex(where: { $0.id == pageId }) else { return }
                comicPages[updatedIndex].hasRegeneratedImage = true
                
                let regeneratedPage = ComicPage(
                    id: regeneratedPageId,
                    imageUrl: newImageUrl,
                    title: page.title,
                    localFilename: filename,
                    imagePrompt: prompt,
                    hasRegeneratedImage: true,
                    isEditableCopy: false
                )
                let insertIndex = min(updatedIndex + 1, comicPages.count)
                comicPages.insert(regeneratedPage, at: insertIndex)
                currentPageIndex = insertIndex
                regenerateState = .success
                AnalyticsManager.track(
                    AnalyticsEvent.imageRegenerationSucceeded,
                    properties: [
                        "page_id": pageId.uuidString,
                        "new_page_id": regeneratedPage.id.uuidString,
                        "story_id": displayedStoryId?.uuidString ?? "",
                        "page_index": insertIndex + 1
                    ]
                )
                syncRegeneratedPagesToStoryStorage(originalPageId: pageId, regeneratedPage: regeneratedPage)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { regenerateState = .idle }
            }
        }
    }

    private func renderEditedImage(for page: ComicPage, overlays: [ComicOverlayItem]) async -> UIImage? {
        let baseImage = await loadUIImage(for: page)
        guard let baseImage else { return nil }

        return await MainActor.run {
            let targetSize = baseImage.size
            let outputScale = max(currentMatScale, 1)
            let previewCanvasSize = CGSize(
                width: max(previewCanvasSizeForExport.width, 1),
                height: max(previewCanvasSizeForExport.height, 1)
            )
            let previewScaledCanvasSize = CGSize(
                width: max(previewScaledCanvasSizeForExport.width, previewCanvasSize.width * outputScale),
                height: max(previewScaledCanvasSizeForExport.height, previewCanvasSize.height * outputScale)
            )
            print("[ComicDisplayView] 开始位图导出，pageId: \(page.id), targetSize: \(targetSize), outputScale: \(outputScale), previewCanvasSize: \(previewCanvasSize), previewScaledCanvasSize: \(previewScaledCanvasSize), baseImageOffset: \(baseImageOffset), overlayCount: \(overlays.count)")
            return renderEditedBitmapImage(
                baseImage: baseImage,
                targetSize: targetSize,
                previewCanvasSize: previewCanvasSize,
                previewScaledCanvasSize: previewScaledCanvasSize,
                outputScale: outputScale,
                baseImageOffset: baseImageOffset,
                overlays: overlays
            )
        }
    }

    @MainActor
    private func renderEditedBitmapImage(baseImage: UIImage, targetSize: CGSize, previewCanvasSize: CGSize, previewScaledCanvasSize: CGSize, outputScale: CGFloat, baseImageOffset: CGSize, overlays: [ComicOverlayItem]) -> UIImage? {
        let exportScaledCanvasSize = CGSize(width: targetSize.width * outputScale, height: targetSize.height * outputScale)
        let exportBaseImageRect = centeredRect(innerSize: targetSize, outerSize: exportScaledCanvasSize)
        let exportOffset = CGSize(
            width: baseImageOffset.width * (exportScaledCanvasSize.width / max(previewScaledCanvasSize.width, 1)),
            height: baseImageOffset.height * (exportScaledCanvasSize.height / max(previewScaledCanvasSize.height, 1))
        )
        let textScale = min(
            targetSize.width / max(previewCanvasSize.width, 1),
            targetSize.height / max(previewCanvasSize.height, 1)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: exportScaledCanvasSize, format: format)

        let image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.interpolationQuality = .high
            cgContext.setAllowsAntialiasing(true)
            cgContext.setShouldAntialias(true)

            for overlay in overlays where overlay.isBackgroundMatKind {
                guard case .backgroundMat(let isWhite, let matScale) = overlay.kind else { continue }
                let matRect = CGRect(
                    x: exportBaseImageRect.midX - (targetSize.width * matScale) / 2,
                    y: exportBaseImageRect.midY - (targetSize.height * matScale) / 2,
                    width: targetSize.width * matScale,
                    height: targetSize.height * matScale
                )
                cgContext.setFillColor((isWhite ? UIColor.white : UIColor.black).cgColor)
                let path = UIBezierPath(roundedRect: matRect, cornerRadius: 10 * textScale)
                cgContext.addPath(path.cgPath)
                cgContext.fillPath()
            }

            let baseRect = CGRect(
                x: exportBaseImageRect.origin.x + exportOffset.width,
                y: exportBaseImageRect.origin.y + exportOffset.height,
                width: targetSize.width,
                height: targetSize.height
            )
            baseImage.draw(in: baseRect)

            for overlay in overlays where !overlay.isBackgroundMatKind {
                switch overlay.kind {
                case .text(let content, let textColorHex, let showsBackground):
                    drawTextOverlay(
                        content: content,
                        textColorHex: textColorHex,
                        showsBackground: showsBackground,
                        overlay: overlay,
                        in: cgContext,
                        exportScaledCanvasSize: exportScaledCanvasSize,
                        exportOffset: exportOffset,
                        textScale: textScale
                    )
                case .image(let data):
                    guard let image = UIImage(data: data) else { continue }
                    drawImageOverlay(
                        image: image,
                        overlay: overlay,
                        in: cgContext,
                        exportScaledCanvasSize: exportScaledCanvasSize,
                        exportOffset: exportOffset,
                        textScale: textScale
                    )
                case .backgroundMat:
                    break
                }
            }
        }

        print("[ComicDisplayView] 位图导出完成，exportScaledCanvasSize: \(exportScaledCanvasSize), exportOffset: \(exportOffset), textScale: \(textScale)")
        return image
    }

    @MainActor
    private func drawTextOverlay(content: String, textColorHex: String, showsBackground: Bool, overlay: ComicOverlayItem, in context: CGContext, exportScaledCanvasSize: CGSize, exportOffset: CGSize, textScale: CGFloat) {
        let effectiveScale = max(overlay.scale * textScale, 0.01)
        let fontSize = ComicDisplayView.textOverlayBaseFontSize * effectiveScale
        let horizontalPadding = ComicDisplayView.textOverlayHorizontalPadding * effectiveScale
        let verticalPadding = ComicDisplayView.textOverlayVerticalPadding * effectiveScale
        let cornerRadius = ComicDisplayView.textOverlayCornerRadius * effectiveScale
        let font = UIFont(name: AppTheme.appFontNameBold, size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let textColor = UIColor(Color(hex: textColorHex))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        let text = NSAttributedString(string: content, attributes: attributes)
        let line = CTLineCreateWithAttributedString(text)
        let bounds = CTLineGetBoundsWithOptions(line, [.useOpticalBounds, .excludeTypographicLeading])
        let ascentPointer = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        let descentPointer = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        let leadingPointer = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        defer {
            ascentPointer.deallocate()
            descentPointer.deallocate()
            leadingPointer.deallocate()
        }
        ascentPointer.initialize(to: 0)
        descentPointer.initialize(to: 0)
        leadingPointer.initialize(to: 0)
        _ = CTLineGetTypographicBounds(line, ascentPointer, descentPointer, leadingPointer)
        let ascent = ascentPointer.pointee
        let descent = descentPointer.pointee
        let textSize = CGSize(width: ceil(bounds.width), height: ceil(ascent + descent))
        let boxSize = CGSize(
            width: ceil(textSize.width + horizontalPadding * 2),
            height: ceil(textSize.height + verticalPadding * 2)
        )
        let center = CGPoint(
            x: overlay.center.x * exportScaledCanvasSize.width + exportOffset.width,
            y: overlay.center.y * exportScaledCanvasSize.height + exportOffset.height
        )
        let boxRect = CGRect(
            x: center.x - boxSize.width / 2,
            y: center.y - boxSize.height / 2,
            width: boxSize.width,
            height: boxSize.height
        )

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: overlay.rotation)
        context.translateBy(x: -center.x, y: -center.y)

        if showsBackground {
            let bgPath = UIBezierPath(roundedRect: boxRect, cornerRadius: cornerRadius)
            context.setFillColor(UIColor.black.withAlphaComponent(0.32).cgColor)
            context.addPath(bgPath.cgPath)
            context.fillPath()
        }

        let textOrigin = CGPoint(
            x: boxRect.origin.x + horizontalPadding - bounds.minX,
            y: boxRect.origin.y + verticalPadding + (boxSize.height - verticalPadding * 2 - textSize.height) / 2 + descent
        )
        context.saveGState()
        context.translateBy(x: 0, y: exportScaledCanvasSize.height)
        context.scaleBy(x: 1, y: -1)
        let flippedOrigin = CGPoint(
            x: textOrigin.x,
            y: exportScaledCanvasSize.height - textOrigin.y - textSize.height
        )
        context.textPosition = flippedOrigin
        CTLineDraw(line, context)
        context.restoreGState()
        context.restoreGState()
    }

    @MainActor
    private func drawImageOverlay(image: UIImage, overlay: ComicOverlayItem, in context: CGContext, exportScaledCanvasSize: CGSize, exportOffset: CGSize, textScale: CGFloat) {
        let overlayWidth = min(exportScaledCanvasSize.width * 0.36, 180 * max(overlay.scale * textScale, 1))
        let aspect = image.size.height / max(image.size.width, 1)
        let overlayHeight = overlayWidth * aspect
        let center = CGPoint(
            x: overlay.center.x * exportScaledCanvasSize.width + exportOffset.width,
            y: overlay.center.y * exportScaledCanvasSize.height + exportOffset.height
        )
        let rect = CGRect(
            x: center.x - overlayWidth / 2,
            y: center.y - overlayHeight / 2,
            width: overlayWidth,
            height: overlayHeight
        )

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: overlay.rotation)
        context.translateBy(x: -center.x, y: -center.y)
        image.draw(in: rect)
        context.restoreGState()
    }

    private func loadUIImage(for page: ComicPage) async -> UIImage? {
        if let filename = page.localFilename,
           let image = ImageCache.shared.loadPersistent(filename: filename) {
            return image
        }
        guard let url = URL(string: page.imageUrl) else { return nil }
        return await ImageCache.shared.load(url: url)
    }

    @MainActor
    private func saveImageToPhotoLibrary(_ image: UIImage, pageId: UUID, overlayCount: Int, keepSuccessState: Bool = true) async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            AnalyticsManager.track(
                AnalyticsEvent.imageSaveFailed,
                properties: [
                    "page_id": pageId.uuidString,
                    "story_id": displayedStoryId?.uuidString ?? "",
                    "page_index": currentPageIndex + 1,
                    "overlay_count": overlayCount,
                    "reason": "photo_permission_denied"
                ]
            )
            saveState = .denied
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { saveState = .idle }
            return
        }
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                DispatchQueue.main.async {
                    print("[ComicDisplayView] 保存到系统相册结果：\(success)")
                    if success {
                        AnalyticsManager.track(
                            AnalyticsEvent.imageSaved,
                            properties: [
                                "page_id": pageId.uuidString,
                                "story_id": displayedStoryId?.uuidString ?? "",
                                "page_index": currentPageIndex + 1,
                                "overlay_count": overlayCount
                            ]
                        )
                    } else {
                        AnalyticsManager.track(
                            AnalyticsEvent.imageSaveFailed,
                            properties: [
                                "page_id": pageId.uuidString,
                                "story_id": displayedStoryId?.uuidString ?? "",
                                "page_index": currentPageIndex + 1,
                                "overlay_count": overlayCount,
                                "reason": "photo_library_write_failed"
                            ]
                        )
                    }
                    if keepSuccessState {
                    saveState = success ? .success : .idle
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { saveState = .idle }
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func syncRegeneratedPagesToStoryStorage(originalPageId: UUID, regeneratedPage: ComicPage) {
        guard let displayedStoryId else {
            print("[ComicDisplayView] 未找到当前故事 ID，无法持久化重绘结果")
            return
        }
        var stories = StoryStorage.shared.loadAll()
        guard let storyIndex = stories.firstIndex(where: { $0.id == displayedStoryId }) else {
            print("[ComicDisplayView] 故事不存在于本地存储，storyId: \(displayedStoryId)")
            return
        }
        guard let pageIndex = stories[storyIndex].pages.firstIndex(where: { $0.id == originalPageId }) else {
            print("[ComicDisplayView] 原页面不存在于故事中，pageId: \(originalPageId)")
            return
        }
        
        stories[storyIndex].pages[pageIndex].hasRegeneratedImage = true
        let insertedPage = StoryPage(
            id: regeneratedPage.id,
            text: stories[storyIndex].pages[pageIndex].text,
            imageUrl: regeneratedPage.imageUrl,
            localImagePath: regeneratedPage.localFilename,
            imagePrompt: regeneratedPage.imagePrompt,
            hasRegeneratedImage: true,
            isEditableCopy: false
        )
        let insertIndex = min(pageIndex + 1, stories[storyIndex].pages.count)
        stories[storyIndex].pages.insert(insertedPage, at: insertIndex)
        let updatedStory = stories[storyIndex]
        StoryStorage.shared.replaceAll(with: stories)
        appState.viewingSavedStory = updatedStory
        print("[ComicDisplayView] 已持久化重绘结果，storyId: \(updatedStory.id), 原页: \(originalPageId), 新页: \(regeneratedPage.id)")
    }

    private func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
    }
}

private func comicFittedRectForCanvas(imageAspect: CGFloat, canvasSize: CGSize) -> CGRect {
    let cw = canvasSize.width
    let ch = canvasSize.height
    guard imageAspect > 0.001 else {
        return CGRect(origin: .zero, size: canvasSize)
    }
    let canvasAspect = cw / max(ch, 1)
    if canvasAspect > imageAspect {
        let h = ch
        let w = h * imageAspect
        let x = (cw - w) / 2
        return CGRect(x: x, y: 0, width: w, height: h)
    } else {
        let w = cw
        let h = w / imageAspect
        let y = (ch - h) / 2
        return CGRect(x: 0, y: y, width: w, height: h)
    }
}

private func fittedCanvasSize(imageAspect: CGFloat, containerSize: CGSize) -> CGSize {
    let fittedRect = comicFittedRectForCanvas(imageAspect: imageAspect, canvasSize: containerSize)
    return CGSize(width: fittedRect.width, height: fittedRect.height)
}

private func centeredRect(innerSize: CGSize, outerSize: CGSize) -> CGRect {
    CGRect(
        x: (outerSize.width - innerSize.width) / 2,
        y: (outerSize.height - innerSize.height) / 2,
        width: innerSize.width,
        height: innerSize.height
    )
}

private struct BackgroundMatPreviewLayer: View {
    @Binding var item: ComicOverlayItem
    let canvasSize: CGSize
    let imageRect: CGRect
    let isSelected: Bool

    private var matScale: CGFloat {
        if case .backgroundMat(_, let s) = item.kind { return s }
        return 1.08
    }

    private var isWhite: Bool {
        if case .backgroundMat(let w, _) = item.kind { return w }
        return false
    }

    var body: some View {
        let outerSize = CGSize(width: imageRect.width * matScale, height: imageRect.height * matScale)
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isWhite ? Color.white : Color.black)
                .frame(width: outerSize.width, height: outerSize.height)
                .position(x: canvasSize.width / 2, y: canvasSize.height / 2)
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "FF1493"), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .frame(width: outerSize.width, height: outerSize.height)
                    .position(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }
}

struct ComicPage {
    let id: UUID
    var imageUrl: String
    let title: String
    var localFilename: String?
    let imagePrompt: String?
    var hasRegeneratedImage: Bool
    var isEditableCopy: Bool = false
}

private struct ComicRenderImageAspectKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

private struct ComicBaseImageOffsetKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

private struct ComicExportTextScaleXKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

private struct ComicExportTextScaleYKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

private extension EnvironmentValues {
    var comicRenderImageAspect: CGFloat {
        get { self[ComicRenderImageAspectKey.self] }
        set { self[ComicRenderImageAspectKey.self] = newValue }
    }

    var comicBaseImageOffset: CGSize {
        get { self[ComicBaseImageOffsetKey.self] }
        set { self[ComicBaseImageOffsetKey.self] = newValue }
    }

    var comicExportTextScaleX: CGFloat {
        get { self[ComicExportTextScaleXKey.self] }
        set { self[ComicExportTextScaleXKey.self] = newValue }
    }

    var comicExportTextScaleY: CGFloat {
        get { self[ComicExportTextScaleYKey.self] }
        set { self[ComicExportTextScaleYKey.self] = newValue }
    }
}

private struct EditableOverlayView: View {
    @Binding var item: ComicOverlayItem
    let canvasSize: CGSize
    let imageRect: CGRect
    var blockPinchRotate: Bool = false
    let onSelect: () -> Void
    let onDoubleTapText: () -> Void

    @State private var dragStartCenter: CGPoint?
    @State private var gestureStartScale: CGFloat?
    @State private var gestureStartRotation: CGFloat?
    @Environment(\.comicBaseImageOffset) private var renderBaseImageOffset
    @Environment(\.comicExportTextScaleX) private var exportTextScaleX
    @Environment(\.comicExportTextScaleY) private var exportTextScaleY

    private var overlayPosition: CGPoint {
        CGPoint(
            x: item.center.x * canvasSize.width + renderBaseImageOffset.width,
            y: item.center.y * canvasSize.height + renderBaseImageOffset.height
        )
    }

    var body: some View {
        Group {
            if blockPinchRotate {
                overlayBody
                    .rotationEffect(.radians(item.rotation))
                    .position(overlayPosition)
                    .gesture(dragGesture)
            } else {
                overlayBody
                    .rotationEffect(.radians(item.rotation))
                    .position(overlayPosition)
                    .gesture(
                        dragGesture
                            .simultaneously(with: magnificationGesture)
                            .simultaneously(with: rotationGesture)
                    )
            }
        }
        .onTapGesture(count: 2) {
            if case .text = item.kind {
                onDoubleTapText()
            } else {
                onSelect()
            }
        }
        .onTapGesture(perform: onSelect)
    }

    @ViewBuilder
    private var overlayBody: some View {
        switch item.kind {
        case .text(let content, let textColorHex, let showsBackground):
            let effectiveScale = item.scale * min(exportTextScaleX, exportTextScaleY)
            Text(content)
                .font(AppTheme.fontBold(size: ComicDisplayView.textOverlayBaseFontSize * effectiveScale))
                .foregroundStyle(Color(hex: textColorHex))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, ComicDisplayView.textOverlayHorizontalPadding * effectiveScale)
                .padding(.vertical, ComicDisplayView.textOverlayVerticalPadding * effectiveScale)
                .background(
                    RoundedRectangle(cornerRadius: ComicDisplayView.textOverlayCornerRadius * effectiveScale)
                        .fill(showsBackground ? Color.black.opacity(0.32) : Color.clear)
                )
        case .image(let imageData):
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(canvasSize.width * 0.36, 180 * max(item.scale, 1)))
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
        case .backgroundMat(isWhite: let isWhite, matScale: let matScale):
            RoundedRectangle(cornerRadius: 10)
                .fill(isWhite ? Color.white : Color.black)
                .frame(width: imageRect.width * matScale, height: imageRect.height * matScale)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartCenter == nil {
                    dragStartCenter = item.center
                }
                guard let start = dragStartCenter else { return }
                let updated = CGPoint(
                    x: start.x + value.translation.width / max(imageRect.width, 1),
                    y: start.y + value.translation.height / max(imageRect.height, 1)
                )
                item.center = updated.clamped()
            }
            .onEnded { _ in
                dragStartCenter = nil
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if gestureStartScale == nil {
                    gestureStartScale = item.scale
                }
                let baseScale = gestureStartScale ?? item.scale
                let newScale = min(max(baseScale * value.magnification, 0.4), 3.2)
                item.scale = newScale
                if case .text(let content, _, _) = item.kind {
                    item.textBoxSize = ComicOverlayItem.measureTextBoxSize(for: content, scale: newScale)
                }
            }
            .onEnded { _ in
                gestureStartScale = nil
            }
    }

    private var rotationGesture: some Gesture {
        RotateGesture()
            .onChanged { value in
                if gestureStartRotation == nil {
                    gestureStartRotation = item.rotation
                }
                let baseRotation = gestureStartRotation ?? item.rotation
                item.rotation = baseRotation + value.rotation.radians
            }
            .onEnded { _ in
                gestureStartRotation = nil
            }
    }
}

private struct ComicOverlayItem: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: Kind
    var center: CGPoint
    var scale: CGFloat
    var rotation: CGFloat
    var textBoxSize: CGSize

    enum Kind: Codable, Equatable {
        case text(content: String, textColorHex: String, showsBackground: Bool)
        case image(data: Data)
        case backgroundMat(isWhite: Bool, matScale: CGFloat)

        private enum CodingKeys: String, CodingKey {
            case type, content, data, isWhite, matScale, textColorHex, showsBackground
        }

        private enum ItemType: String, Codable {
            case text, image, backgroundMat
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ItemType.self, forKey: .type)
            switch type {
            case .text:
                self = .text(
                    content: try container.decode(String.self, forKey: .content),
                    textColorHex: try container.decodeIfPresent(String.self, forKey: .textColorHex) ?? "000000",
                    showsBackground: try container.decodeIfPresent(Bool.self, forKey: .showsBackground) ?? false
                )
            case .image:
                self = .image(data: try container.decode(Data.self, forKey: .data))
            case .backgroundMat:
                self = .backgroundMat(
                    isWhite: try container.decode(Bool.self, forKey: .isWhite),
                    matScale: try container.decode(CGFloat.self, forKey: .matScale)
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let content, let textColorHex, let showsBackground):
                try container.encode(ItemType.text, forKey: .type)
                try container.encode(content, forKey: .content)
                try container.encode(textColorHex, forKey: .textColorHex)
                try container.encode(showsBackground, forKey: .showsBackground)
            case .image(let data):
                try container.encode(ItemType.image, forKey: .type)
                try container.encode(data, forKey: .data)
            case .backgroundMat(let isWhite, let matScale):
                try container.encode(ItemType.backgroundMat, forKey: .type)
                try container.encode(isWhite, forKey: .isWhite)
                try container.encode(matScale, forKey: .matScale)
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, center, scale, rotation, textBoxSize
    }

    static func text(content: String, center: CGPoint, textColorHex: String = "000000", showsBackground: Bool = false) -> ComicOverlayItem {
        ComicOverlayItem(
            id: UUID(),
            kind: .text(content: content, textColorHex: textColorHex, showsBackground: showsBackground),
            center: center,
            scale: 1,
            rotation: 0,
            textBoxSize: measureTextBoxSize(for: content, scale: 1)
        )
    }

    static func image(uiImage: UIImage, center: CGPoint) -> ComicOverlayItem {
        ComicOverlayItem(
            id: UUID(),
            kind: .image(data: uiImage.pngData() ?? Data()),
            center: center,
            scale: 1,
            rotation: 0,
            textBoxSize: .zero
        )
    }

    static func backgroundMat(isWhite: Bool, matScale: CGFloat, center: CGPoint) -> ComicOverlayItem {
        ComicOverlayItem(
            id: UUID(),
            kind: .backgroundMat(isWhite: isWhite, matScale: matScale),
            center: center,
            scale: 1,
            rotation: 0,
            textBoxSize: .zero
        )
    }

    static func measureTextBoxSize(for content: String, scale: CGFloat) -> CGSize {
        let font = UIFont(name: AppTheme.appFontNameBold, size: ComicDisplayView.textOverlayBaseFontSize)
            ?? UIFont.systemFont(ofSize: ComicDisplayView.textOverlayBaseFontSize, weight: .bold)
        let textSize = (content as NSString).size(withAttributes: [.font: font])
        return CGSize(
            width: ceil(textSize.width + ComicDisplayView.textOverlayHorizontalPadding * 2),
            height: ceil(textSize.height + ComicDisplayView.textOverlayVerticalPadding * 2)
        )
    }

    var isBackgroundMatKind: Bool {
        if case .backgroundMat = kind { return true }
        return false
    }

    var displayText: String {
        if case .text(let content, _, _) = kind {
            return content
        }
        return ""
    }

}

private extension CGPoint {
    func clamped() -> CGPoint {
        CGPoint(x: min(max(x, 0.08), 0.92), y: min(max(y, 0.08), 0.92))
    }
}

#Preview {
    ComicDisplayView(isPresented: .constant(true))
}
