//
//  FileManager.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//
import Cocoa
import Foundation

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
    openPanel.directoryURL = URL(fileURLWithPath: FileHelper.standard.getDefaultXcodePath())
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
  
  /// 单个文件真正占用的磁盘空间（已分配的块），而非其声明长度。
  ///
  /// 必须用 `totalFileAllocatedSize` 而不是 `FileAttributeKey.size`：后者是 `stat.st_size`，
  /// 即文件声明的逻辑长度。Xcode 的 `CompilationCache.noindex` 把 CAS 存储建成稀疏文件
  /// （`v9.data` 一上来就声明 24 GiB，实际只写了约 1 MB），按 st_size 统计会虚报上万倍。
  ///
  /// 只统计普通文件：符号链接若被解析会与其目标重复计数，而目录 inode 在 APFS 上不额外占块。
  private func allocatedSize(of url: URL, keys: Set<URLResourceKey>) -> UInt64 {
    guard let values = try? url.resourceValues(forKeys: keys),
          values.isRegularFile == true else {
      return 0
    }

    // totalFileAllocatedSize 含资源分支等附加数据，取不到时退回主数据分支的大小
    return UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
  }

  /// 递归统计目录（或单个文件）占用的磁盘空间，单位字节。
  ///
  /// 结果与 `du` 一致，会小于 Finder 显示的「大小」——后者同样是逻辑长度。
  /// 无法读取的条目按 0 计入并继续遍历，不会让整个目录的统计失败。
  func getDirectorySize(_ path: String) throws -> UInt64 {
    let fm = FileManager.default
    let url = URL(fileURLWithPath: path)
    let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey]

    var isDirectory = ObjCBool(false)
    guard fm.fileExists(atPath: path, isDirectory: &isDirectory) else {
      return 0
    }

    guard isDirectory.boolValue else {
      return allocatedSize(of: url, keys: keys)
    }

    // 用 enumerator 惰性遍历，避免 subpaths(atPath:) 对 DerivedData 这类
    // 动辄数万条目的目录一次性构造完整路径数组
    guard let enumerator = fm.enumerator(
      at: url,
      includingPropertiesForKeys: Array(keys),
      options: [],
      errorHandler: { _, _ in true }  // 单个条目读不到就跳过，继续遍历
    ) else {
      return 0
    }

    var size: UInt64 = 0

    for case let fileURL as URL in enumerator {
      size += allocatedSize(of: fileURL, keys: keys)
    }

    return size
  }
  
  func getDirectoryUpdateDate(_ path: String) throws -> Date {
    let fileAttrs = try FileManager.default.attributesOfItem(atPath: path)
    return fileAttrs[FileAttributeKey.modificationDate] as! Date
  }
}
