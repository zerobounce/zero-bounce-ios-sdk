//
//  ZBFileManager.swift
//  ZeroBounceExample
//
//  Created by ZeroBounce on 10/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

internal class ZBFileManager {
    
    internal enum WriteFileResult {
        case success(String)
        case failure(Error)
    }
    
    internal static func writeFile(text:String, to fileNamed: String, folder: String = "SavedFiles", result: @escaping (WriteFileResult) -> ()) {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            result(.failure(ZBError.saveFileError(message: "Cannot access downloads directory")))
            return
        }
        
        guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent(folder) else {
            result(.failure(ZBError.saveFileError(message: "Cannot access folder \(folder)")))
            return
        }
        
        do {
            try FileManager.default.createDirectory(atPath: writePath.path, withIntermediateDirectories: true)
        } catch {
            result(.failure(ZBError.saveFileError(message: "Cannot create directory \(writePath.path)")))
            return
        }
        
        let safeName = (fileNamed as NSString).lastPathComponent
        guard !safeName.isEmpty, safeName != ".", safeName != "..", safeName != "/" else {
            result(.failure(ZBError.saveFileError(message: "Invalid file name")))
            return
        }
        let file = writePath.appendingPathComponent(safeName)
        
        do {
            try replaceFile(at: file, with: Data(text.utf8))
        } catch {
            result(.failure(ZBError.saveFileError(message: "Cannot write to file \(file.path)")))
            return
        }
        
        result(.success(file.path))
    }

    /// A temporary name for a file being written next to `target`, in the
    /// same directory so the final rename stays on one volume.
    private static func temporaryURL(beside target: URL) -> URL {
        target.deletingLastPathComponent()
            .appendingPathComponent(".\(target.lastPathComponent).\(UUID().uuidString).zbtmp")
    }

    /// Renames `temporary` over `target` in one step, or removes it and
    /// throws: `target` is either the old file or the complete new one.
    private static func commit(_ temporary: URL, over target: URL) throws {
        if rename(temporary.path, target.path) != 0 {
            let code = errno
            try? FileManager.default.removeItem(at: temporary)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [
                NSFilePathErrorKey: target.path
            ])
        }
    }

    /// Writes `data` to `target` through a temporary file in the same
    /// directory, renamed over `target` only once it is complete. A write
    /// that fails (a full disk, a file size limit) leaves a file already at
    /// `target` as it was, and no partial file.
    internal static func replaceFile(at target: URL, with data: Data) throws {
        let temporary = temporaryURL(beside: target)
        do {
            try data.write(to: temporary, options: .withoutOverwriting)
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
        try commit(temporary, over: target)
    }

    /// Moves the file at `source` to `target` the same way: to a temporary
    /// file beside `target` first (a copy when `source` is on another
    /// volume, which can fail part way), then renamed over `target`.
    internal static func replaceFile(at target: URL, withContentsOf source: URL) throws {
        let temporary = temporaryURL(beside: target)
        do {
            try FileManager.default.moveItem(at: source, to: temporary)
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
        try commit(temporary, over: target)
    }
}
