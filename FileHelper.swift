//
//  FileManager.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//
import Cocoa
import Foundation

extension String {
  func joinPath(_ subPath: String) -> String {
    if self.hasSuffix("/") {
      return self + subPath
    }
    return self + "/" + subPath
  }
}


class FileHelper {
  public static let standard = FileHelper()
  
  func getDefaultXcodePath() -> String {
    var homeDirectory = NSHomeDirectory();
    let sandboxPrefix = "/Library/Containers/";
    
    if homeDirectory.contains(sandboxPrefix) {
      if let range = homeDirectory.range(of: sandboxPrefix){
        homeDirectory = String(homeDirectory[..<range.lowerBound])
      }
    }
    
    return "\(homeDirectory)/Library/Developer/"
  }

  func validateDeveloperPath(path: String) -> Bool {
    let xcodePath = path.joinPath("Xcode");
    var isDirectory = ObjCBool(true)
    return FileManager.default.fileExists(atPath: xcodePath, isDirectory: &isDirectory) && isDirectory.boolValue
  }
  
  func authorize(_ path: String?, callback: @escaping (String) -> Void){
    if let path = path, let bookmarkData = UserDefaults.standard.object(forKey: bookmarkKey(path)){
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
    openPanel.showsHiddenFiles = true
    openPanel.begin { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        let url = openPanel.urls.first!
        print("selected url", url, url.path)
        do{
          let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
          UserDefaults.standard.setValue(bookmarkData, forKey: bookmarkKey(url: url))
          _ = self.resolveBookmark(data: bookmarkData)
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
      let url = try NSURL(resolvingBookmarkData: data, options: URL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
      
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
    
    let filenames = try FileManager.default.contentsOfDirectory(atPath: path)
    
    for filename in filenames {
      if filename == ".DS_Store" {
        continue
      }
      
      let fullPath = path.hasSuffix("/") ? path + filename : path + "/" + filename
      var isDirectory = ObjCBool(false)
      FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
      
      if (!onlyDirectory){
        results.append(fullPath)
        
      } else if (isDirectory).boolValue{
        results.append(fullPath)
      }
    }
    
    return results
  }
  
  func getDirectorySize(_ path: String) throws -> UInt64{
    var size: UInt64 = 0
    let fm = FileManager.default
    
    var isDirectory = ObjCBool(true)
    
    var contents: [String]
    
    fm.fileExists(atPath: path, isDirectory: &isDirectory)
    if isDirectory.boolValue {
      guard let subpaths = fm.subpaths(atPath: path) else {
        return 0
      }
      
      contents = subpaths.map { subPath in
        path.joinPath(subPath)
      }

    } else {
      contents = [path]
    }

    for subpath in contents {
      let fileAttrs = try fm.attributesOfItem(atPath: subpath)
      size += fileAttrs[FileAttributeKey.size] as! UInt64
    }
    
    return size;
  }
  
  func getDirectoryUpdateDate(_ path: String) throws -> Date {
    let fileAttrs = try FileManager.default.attributesOfItem(atPath: path)
    return fileAttrs[FileAttributeKey.modificationDate] as! Date
  }
}
