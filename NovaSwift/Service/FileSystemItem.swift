//
//  FileSystemItem.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 05.01.26.
//

import Foundation

/// A model representing a file or directory within the project's file system.
///
/// `FileSystemItem` is designed for use in SwiftUI `List` and `OutlineGroup` views.
/// It conforms to `Identifiable` for stable identity and `Hashable` for diffing.
/// The structure is recursive, with the `children` property allowing it to represent
/// a nested directory tree.
struct FileSystemItem: Identifiable, Hashable {
    /// A unique identifier for the item, generated at initialization.
    let id = UUID()
    
    /// The name of the file or directory (including extension).
    let name: String
    
    /// The absolute URL to the item on disk.
    let url: URL
    
    /// A boolean indicating whether this item is a directory.
    let isDirectory: Bool
    
    /// The contents of the directory, if this item is a folder. `nil` for files.
    var children: [FileSystemItem]?
}
