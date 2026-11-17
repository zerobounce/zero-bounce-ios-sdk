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
    /// path is empty, ends with a separator or with a `.` or `..` component
    /// (each names a directory), or is an existing directory (a symlink to
    /// one included). Checked before the
    /// request is sent, so a call that cannot save its file costs no request.
    internal static func downloadPathFailure(_ path: String) -> ZBError? {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .decodeError(messages: ["Empty parameter: downloadPath"])
        }
        guard !path.hasSuffix("/") else {
            return .decodeError(messages: ["Invalid parameter: downloadPath (it ends with a path separator, so it names a directory)"])
        }
        // `.` and `..` name a directory even when the path before them does
        // not exist yet, so the check below would not see it.
        if let last = path.split(separator: "/", omittingEmptySubsequences: false).last, last == "." || last == ".." {
            return .decodeError(messages: ["Invalid parameter: downloadPath (it ends with \"\(last)\", so it names a directory)"])
        }
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
            return .decodeError(messages: ["Invalid parameter: downloadPath (it is an existing directory)"])
        }
        return nil
    }

    /// `target` with a chain of symbolic links followed to the file they
    /// lead to, which may not exist yet (a dangling link): a download is
    /// written through a link, never in place of it. A chain that does not
    /// end within 40 links (a loop included) throws ELOOP, so the write
    /// fails rather than replacing a link with a regular file.
    private static func resolvingLinks(_ target: URL) throws -> URL {
        var current = target
        for _ in 0..<40 {
            guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: current.path) else {
                return current
            }
            current = destination.hasPrefix("/")
                ? URL(fileURLWithPath: destination)
                : current.deletingLastPathComponent().appendingPathComponent(destination)
        }
        // The 40th link led to something: it is the file only when it is not
        // another link.
        if (try? FileManager.default.destinationOfSymbolicLink(atPath: current.path)) != nil {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(ELOOP), userInfo: [
                NSFilePathErrorKey: target.path
            ])
        }
        return current
    }

    /// A temporary name for a file being written next to `target`, in the
    /// same directory so the final rename stays on one volume. It does not
    /// carry the target's name: a last component near the 255-byte limit
    /// would leave no room for a suffix.
    private static func temporaryURL(beside target: URL) -> URL {
        target.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).zbtmp")
    }

    /// Test seam: called with the temporary file right after it is created,
    /// before any data is written to it.
    internal static var afterTemporaryCreated: ((URL) -> Void)?

    /// Creates the empty temporary file `temporary` for a write to `target`
    /// with its final permission bits already set, before any data goes in:
    /// those of a regular file already at `target`, else the default creation
    /// mode (0666 minus the umask). It is created exclusively and never more
    /// permissive than the file it will replace, so the content of a 0600
    /// target is not readable by others while it is written. Returns the open
    /// descriptor; the caller closes it.
    private static func createTemporary(_ temporary: URL, for target: URL) throws -> Int32 {
        var finalMode: mode_t?
        var info = stat()
        if stat(target.path, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG {
            finalMode = info.st_mode & 0o7777
        }
        let fd = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
                      finalMode == nil ? 0o666 : 0o600)
        if fd < 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [
                NSFilePathErrorKey: target.path
            ])
        }
        if let finalMode = finalMode, fchmod(fd, finalMode) != 0 {
            let code = errno
            close(fd)
            try? FileManager.default.removeItem(at: temporary)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [
                NSFilePathErrorKey: target.path
            ])
        }
        afterTemporaryCreated?(temporary)
        return fd
    }

    /// Writes all of `data` to `fd`.
    private static func writeAll(_ data: Data, to fd: Int32, path: String) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            var offset = 0
            while offset < buffer.count {
                let written = write(fd, buffer.baseAddress! + offset, buffer.count - offset)
                if written < 0 {
                    if errno == EINTR { continue }
                    throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [
                        NSFilePathErrorKey: path
                    ])
                }
                offset += written
            }
        }
    }

    /// Renames `temporary` over `target` in one step, or removes it and
    /// throws: `target` is either the old file or the complete new one. The
    /// temporary file already has the permissions of a file at `target`.
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
    /// `target` as it was, and no partial file. A symbolic link at `target`
    /// is written through to the file it points to, and a file already there
    /// keeps its permissions, which the temporary file has from its creation.
    internal static func replaceFile(at requested: URL, with data: Data) throws {
        let target = try resolvingLinks(requested)
        let temporary = temporaryURL(beside: target)
        let fd = try createTemporary(temporary, for: target)
        do {
            try writeAll(data, to: fd, path: temporary.path)
            close(fd)
        } catch {
            close(fd)
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
        try commit(temporary, over: target)
    }

    /// Moves the file at `source` to `target` the same way: copied in chunks
    /// into a temporary file beside `target` that is created with the final
    /// permissions first, then renamed over `target`, through a symbolic link
    /// and keeping the permissions of a file already there. `source` is
    /// removed once the copy is complete.
    internal static func replaceFile(at requested: URL, withContentsOf source: URL) throws {
        let target = try resolvingLinks(requested)
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }
        let temporary = temporaryURL(beside: target)
        let fd = try createTemporary(temporary, for: target)
        do {
            while let chunk = try input.read(upToCount: 1 << 20), !chunk.isEmpty {
                try writeAll(chunk, to: fd, path: temporary.path)
            }
            close(fd)
        } catch {
            close(fd)
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
        try commit(temporary, over: target)
        try? FileManager.default.removeItem(at: source)
    }
}
