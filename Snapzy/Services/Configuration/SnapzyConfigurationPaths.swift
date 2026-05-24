//
//  SnapzyConfigurationPaths.swift
//  Snapzy
//
//  Path helpers for user-managed configuration files.
//

import Darwin
import Foundation

nonisolated enum SnapzyConfigurationPaths {
  static var userHomeDirectory: URL {
    if let accountHomeDirectory {
      return accountHomeDirectory
    }

    return FileManager.default.homeDirectoryForCurrentUser
  }

  static var suggestedConfigURL: URL {
    userHomeDirectory
      .appendingPathComponent(".config", isDirectory: true)
      .appendingPathComponent("snapzy", isDirectory: true)
      .appendingPathComponent("config.toml")
  }

  static func expandedUserPath(_ path: String) -> String {
    guard path.hasPrefix("~/") else { return path }
    return userHomeDirectory
      .appendingPathComponent(String(path.dropFirst(2)))
      .path
  }

  static func suggestedConfigURL(homeDirectory: URL) -> URL {
    homeDirectory
      .appendingPathComponent(".config", isDirectory: true)
      .appendingPathComponent("snapzy", isDirectory: true)
      .appendingPathComponent("config.toml")
  }

  static func expandedUserPath(_ path: String, homeDirectory: URL) -> String {
    guard path.hasPrefix("~/") else { return path }
    return homeDirectory
      .appendingPathComponent(String(path.dropFirst(2)))
      .path
  }

  private static var accountHomeDirectory: URL? {
    guard
      let passwd = getpwuid(getuid()),
      let home = passwd.pointee.pw_dir
    else {
      return nil
    }

    let path = String(cString: home)
    guard !path.isEmpty else { return nil }
    return URL(fileURLWithPath: path, isDirectory: true)
  }
}
