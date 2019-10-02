//
//  FileManager.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//
import Cocoa
import Foundation


class FileDataManager {
    public static let shared = FileDataManager()
    
    func getDefaultXcodePath() -> String{
        var homeDirectory = NSHomeDirectory();
        let sandboxPrefix = "/Library/Containers/";
        
        if homeDirectory.contains(sandboxPrefix) {
            // production mode
            if let range = homeDirectory.range(of: sandboxPrefix){
                homeDirectory = String(homeDirectory[..<range.lowerBound])
            }
        }
        
        return "\(homeDirectory)/Library/Developer/"
    }
    
    func findDeveloperPath(default defualtPath: String, callback: @escaping (String) -> Void){
        do {
            authorize(defualtPath){
                var authorizedPath = $0
                
                if !authorizedPath.hasSuffix("/"){
                    authorizedPath += "/"
                }
                
                print("authorizedPath", authorizedPath);
                
                let xcodePath = authorizedPath + "Xcode/";
                let exists = FileManager.default.fileExists(atPath: xcodePath, isDirectory: nil)
                
                if exists {
                    callback(authorizedPath)
                    return
                }
                
            
                let alert = NSAlert()
                
                alert.messageText = XCODE_NOT_FOUND
                alert.informativeText = XCODE_NOT_FOUND_MSG
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Choose Directory")
                alert.addButton(withTitle: "Cancel")
                
                if alert.runModal() == .alertFirstButtonReturn{
                    self.findDeveloperPath(default: defualtPath, callback: callback)
                } else {
                    return
                }
                
            };
        } catch {
            print("Error: \(error)")
        }
    }
    
    func authorize(_ path: String, callback: @escaping (String) -> Void){
         if let bookmarkData = UserDefaults.standard.object(forKey: bookmarkKey(path)){
             if self.resolveBookmark(data: bookmarkData as! Data){
                 callback(path)
                 return
             }
         }
         
         let openPanel = NSOpenPanel()
         openPanel.allowsMultipleSelection = false
         openPanel.canChooseDirectories = true
         openPanel.canCreateDirectories = false
         openPanel.canChooseFiles = false
         //        openPanel.title = CHOOSE_DEVELOPER_DIR
         openPanel.message = "\(CHOOSE_DEVELOPER_DIR)\n\(CHOOSE_DEVELOPER_DIR_TIP)"
         openPanel.begin { (result) -> Void in
             if result.rawValue == NSFileHandlingPanelOKButton {
                 let url = openPanel.urls.first!
                 do{
                     let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                     UserDefaults.standard.setValue(bookmarkData, forKey: bookmarkKey(url: url))
                     self.resolveBookmark(data: bookmarkData)
                     callback(url.path)
                 } catch {
                     alert(error.localizedDescription)
                 }
             }
         }
     }
     
     func resolveBookmark(data: Data) -> Bool{
         do{
             var isStale = ObjCBool(false)
             var url = try NSURL(resolvingBookmarkData: data, options: URL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
             
             print("resolved url \(url)")
             
             if isStale.boolValue{
                 print("renew bookmark data")
                 let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                 UserDefaults.standard.setValue(bookmark, forKey:bookmarkKey(url.path!))
             }
             
             if !url.startAccessingSecurityScopedResource(){
                 alert("Failed to access sandbox files")
             }
             
             print("Started accessing")
             return true
             
         } catch {
             alert(error.localizedDescription)
             return false
         }
     }
    
    func listDirectory(_ path: String, onlyDirectory: Bool) throws -> [String]{
        var results = [String]()
        
        do {
            
            let filenames = try FileManager.default.contentsOfDirectory(atPath: path)
            
            for filename in filenames{
                let fullPath = path + filename
                var isDirectory = ObjCBool(false)
                FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                
                if (!onlyDirectory){
                    results.append(fullPath)
                    
                } else if (isDirectory).boolValue{
                    results.append(fullPath)
                }
            }
        } catch {
            print("Error \(error)")
        }
        
        return results
    }
    
    func getDirectorySize(_ path: String) throws -> UInt64{
        var size: UInt64 = 0
        
        let contents = FileManager.default.subpaths(atPath: path)
        //        print("subPaths: \(contents)")
        
        for subpath in contents!{
            let fileAttrs = try FileManager.default.attributesOfItem(atPath: path + subpath)
            size += fileAttrs[FileAttributeKey.size] as! UInt64
        }
        
        print("total size", size)
        return size;
    }
}
