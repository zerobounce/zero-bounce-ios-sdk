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

    /// Why a download cannot be written to `path`, or nil when it can: the
    /// path is empty, ends with a separator (it names a directory), or is an
    /// existing directory (a symlink to one included). Checked before the
    /// request is sent, so a call that cannot save its file costs no request.
    internal static func downloadPathFailure(_ path: String) -> ZBError? {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .decodeError(messages: ["Empty parameter: downloadPath"])
        }
        guard !path.hasSuffix("/") else {
            return .decodeError(messages: ["Invalid parameter: downloadPath (it ends with a path separator, so it names a directory)"])
        }
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
            return .decodeError(messages: ["Invalid parameter: downloadPath (it is an existing directory)"])
        }
        return nil
    }

    /// `target` with a chain of symbolic links followed to the file they
    /// lead to, which may not exist yet (a dangling link): a download is
    /// written through a link, never in place of it. A link chain longer
    /// than 40 stops there and fails when the file is written.
    private static func resolvingLinks(_ target: URL) -> URL {
        var current = target
        for _ in 0..<40 {
            guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: current.path) else {
                return current
            }
            current = destination.hasPrefix("/")
                ? URL(fileURLWithPath: destination)
                : current.deletingLastPathComponent().appendingPathComponent(destination)
        }
        return current
    }

    /// A temporary name for a file being written next to `target`, in the
    /// same directory so the final rename stays on one volume.
    private static func temporaryURL(beside target: URL) -> URL {
        target.deletingLastPathComponent()
            .appendingPathComponent(".\(target.lastPathComponent).\(UUID().uuidString).zbtmp")
    }

    /// Renames `temporary` over `target` in one step, or removes it and
    /// throws: `target` is either the old file or the complete new one. A
    /// file already at `target` keeps its permissions.
    private static func commit(_ temporary: URL, over target: URL) throws {
        do {
            if let existing = try? FileManager.default.attributesOfItem(atPath: target.path),
               existing[.type] as? FileAttributeType == .typeRegular,
               let permissions = existing[.posixPermissions] as? NSNumber {
                try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: temporary.path)
            }
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
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
    /// `target` as it was, and no partial file. A symbolic link at `target`
    /// is written through to the file it points to, and a file already there
    /// keeps its permissions.
    internal static func replaceFile(at requested: URL, with data: Data) throws {
        let target = resolvingLinks(requested)
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
    /// volume, which can fail part way), then renamed over `target`, through
    /// a symbolic link and keeping the permissions of a file already there.
    internal static func replaceFile(at requested: URL, withContentsOf source: URL) throws {
        let target = resolvingLinks(requested)
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
