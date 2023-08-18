//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/26/21.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import Foundation

struct EmojiArtModel {
  var background = Background.blank
  var emojis = [Emoji]()
    
  struct Emoji: Identifiable, Hashable {
    let text: String
    var x: Int // offset from the center
    var y: Int // offset from the center
    var size: Int
    let id: Int
    var isSelected: Bool
        
    fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int, isSelected: Bool) {
      self.text = text
      self.x = x
      self.y = y
      self.size = size
      self.id = id
      self.isSelected = isSelected
    }
  }
    
  init() {}
    
  private var uniqueEmojiId = 0
    
  mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
    uniqueEmojiId += 1
    emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId, isSelected: false))
  }
    
  mutating func selectEmoji(_ id: Int) {
    if let selectedIndex = emojis.firstIndex(where: { $0.id == id }) {
      emojis[selectedIndex].isSelected.toggle()
    }
  }
    
  mutating func delete(_ id: Int) {
    if let selectedIndex = emojis.firstIndex(where: { $0.id == id }) {
      emojis.remove(at: selectedIndex)
    }
  }
    
  mutating func deselectAll() {
    for i in 0 ..< emojis.count {
      emojis[i].isSelected = false
    }
  }
}
