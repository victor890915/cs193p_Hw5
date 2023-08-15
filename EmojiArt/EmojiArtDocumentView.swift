//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/26/21.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var haveSelections: Bool { document.selected.count == 0 ? false : true }
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                )
                .gesture(doubleTapToZoom(in: geometry.size)
                    .simultaneously(with: singleTapToDeselectAll()))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        ZStack{
                            Text(emoji.text)
                                .font(.system(size: fontSize(for: emoji)))
                                .scaleEffect(zoomScale * emojiZoomScale)
                                .position(position(for: emoji, in: geometry))
                                .gesture(singleTapToSelect(emoji: emoji).simultaneously(with: DoubleTapToDelete(emoji: emoji)))
                            if(emoji.isSelected){
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.red, lineWidth: 3)
                                    .frame(width: fontSize(for: emoji) * 1.1,
                                           height: fontSize(for: emoji) * 1.1)
                                    .scaleEffect(zoomScale * emojiZoomScale)
                                    .position(position(for: emoji, in: geometry))
                            }
                            
                        }
                        .contextMenu{
                            Button("Delete"){
                                print("delete")
                            }
                        }
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText,.url,.image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
        }
    }
    
    // MARK: - selecting and deleting emojis
    
    private func singleTapToSelect(emoji: EmojiArtModel.Emoji) -> some Gesture{
        TapGesture(count: 1)
            .onEnded{
                document.selectEmoji(emoji.id)
            }
        
    }
    private func DoubleTapToDelete(emoji: EmojiArtModel.Emoji) -> some Gesture{
        TapGesture(count: 2)
            .onEnded{
                document.deleteEmoji(emoji.id)
            }
        
    }
    
    
    // MARK: - Drag and Drop
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        return found
    }
    
    // MARK: - Positioning/Sizing Emoji
    

    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        if emoji.isSelected{
            return convertFromEmojiCoordinates((emoji.x + Int(selectedEmojiOffset.width), emoji.y + Int(selectedEmojiOffset.height)), in: geometry)
        }
        else{
            return convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
        }
     
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    // MARK: - Dedselecting
    
    private func singleTapToDeselectAll() -> some Gesture{
        TapGesture(count: 1)
            .onEnded{
                document.deselectAll()
            }
        
    }
    // MARK: - Zooming
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    @State private var emojiSteadyStateZoomScale: CGFloat = 1
    @GestureState private var emojiGestureZoomScale: CGFloat = 1
    
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    private var emojiZoomScale: CGFloat {
        emojiSteadyStateZoomScale * emojiGestureZoomScale
    }
    
    
    
    private func zoomGesture() -> some Gesture {
        if !haveSelections{
            return MagnificationGesture()
                .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                    gestureZoomScale = latestGestureScale
                }
                .onEnded { gestureScaleAtEnd in
                    steadyStateZoomScale *= gestureScaleAtEnd
                }
        }else{
            return MagnificationGesture()
                .updating($emojiGestureZoomScale) { latestGestureScale, emojiGestureZoomScale, _ in
                    emojiGestureZoomScale = latestGestureScale
                }
                .onEnded { gestureScaleAtEnd in
                    emojiSteadyStateZoomScale *= gestureScaleAtEnd
                }
        }
    }
    

    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0  {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    // MARK: - Panning
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    @GestureState private var selectedEmojiOffset: CGSize = CGSize.zero

    private func panGesture() -> some Gesture {
        if !haveSelections{
            return DragGesture()
                .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                    gesturePanOffset = latestDragGestureValue.translation / zoomScale
                }
                .onEnded { finalDragGestureValue in
                    steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
                }
        }else{
            return DragGesture()
                .updating($selectedEmojiOffset){ latestDragGestureValue, selectedEmojiOffset, _ in
                    
                    selectedEmojiOffset = latestDragGestureValue.translation
                    
                }.onEnded{ finalDragGestureValue in
                    document.moveSelectedEmojis(by: finalDragGestureValue.translation)
                }
        }
       
    }

    // MARK: - Palette
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "😀😷🦠💉👻👀🐶🌲🌎🌞🔥🍎⚽️🚗🚓🚲🛩🚁🚀🛸🏠⌚️🎁🗝🔐❤️⛔️❌❓✅⚠️🎶➕➖🏳️"
}

struct ScrollingEmojisView: View {
    let emojis: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
