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
        
        let file = writePath.appendingPathComponent(fileNamed)
        
        do {
            try text.write(to: file, atomically: false, encoding: .utf8)
        } catch {
            result(.failure(ZBError.saveFileError(message: "Cannot write to file \(file.path)")))
            return
        }
        
        result(.success(file.path))
    }
    

}
