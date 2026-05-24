//
//  SnapzyConfigurationService.swift
//  Snapzy
//
//  Facade for exporting and importing Snapzy TOML configuration files.
//

import Foundation

@MainActor
final class SnapzyConfigurationService {
  static let shared = SnapzyConfigurationService()

  private init() {}

  var suggestedConfigURL: URL {
    SnapzyConfigurationPaths.suggestedConfigURL
  }

  func exportTOML() -> String {
    SnapzyConfigurationExporter.exportTOML()
  }

  func export(to url: URL) throws {
    let toml = exportTOML()
    let directory = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try toml.write(to: url, atomically: true, encoding: .utf8)
  }

  func importTOML(_ source: String) -> SnapzyConfigurationImportResult {
    SnapzyConfigurationImporter.importTOML(source)
  }

  func `import`(from url: URL) throws -> SnapzyConfigurationImportResult {
    let source = try String(contentsOf: url, encoding: .utf8)
    return importTOML(source)
  }
}
