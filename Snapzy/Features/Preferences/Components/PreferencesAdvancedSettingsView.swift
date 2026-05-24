//
//  PreferencesAdvancedSettingsView.swift
//  Snapzy
//
//  Advanced preferences for portable app configuration.
//

import SwiftUI
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
  @State private var resultMessage: String?
  @State private var resultIssues: [SnapzyConfigurationIssue] = []
  @State private var lastConfigURL: URL?

  private let service = SnapzyConfigurationService.shared
  private let tomlContentType = UTType(filenameExtension: "toml") ?? .plainText

  var body: some View {
    Form {
      Section(L10n.PreferencesAdvanced.backupSection) {
        SettingRow(
          icon: "square.and.arrow.up",
          title: L10n.PreferencesAdvanced.exportTitle,
          description: L10n.PreferencesAdvanced.exportDescription
        ) {
          Button(L10n.PreferencesAdvanced.exportButton) {
            exportConfig()
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
        }

        SettingRow(
          icon: "square.and.arrow.down",
          title: L10n.PreferencesAdvanced.importTitle,
          description: L10n.PreferencesAdvanced.importDescription
        ) {
          Button(L10n.PreferencesAdvanced.importButton) {
            importConfig()
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }

        HStack {
          Spacer()

          Button(L10n.PreferencesAdvanced.openConfigButton) {
            openConfigFile()
          }
          .buttonStyle(.link)
          .controlSize(.small)
        }
      }

      if let resultMessage {
        Section(L10n.PreferencesAdvanced.lastResultSection) {
          AdvancedResultSummaryRow(
            message: resultMessage,
            severity: resultSeverity
          )

          if !errorIssues.isEmpty {
            AdvancedResultIssueGroup(
              title: L10n.PreferencesAdvanced.errorsTitle(errorIssues.count),
              icon: "xmark.octagon.fill",
              color: .red,
              issues: errorIssues
            )
          }

          if !warningIssues.isEmpty {
            AdvancedResultIssueGroup(
              title: L10n.PreferencesAdvanced.warningsTitle(warningIssues.count),
              icon: "exclamationmark.triangle.fill",
              color: .orange,
              issues: warningIssues
            )
          }
        }
      }
    }
    .formStyle(.grouped)
  }

  private var errorIssues: [SnapzyConfigurationIssue] {
    resultIssues.filter { $0.severity == .error }
  }

  private var warningIssues: [SnapzyConfigurationIssue] {
    resultIssues.filter { $0.severity == .warning }
  }

  private var resultSeverity: SnapzyConfigurationIssueSeverity? {
    if !errorIssues.isEmpty {
      return .error
    }
    if !warningIssues.isEmpty {
      return .warning
    }
    return nil
  }

  private func exportConfig() {
    let panel = NSSavePanel()
    panel.title = L10n.PreferencesAdvanced.exportPanelTitle
    panel.nameFieldStringValue = "config.toml"
    panel.directoryURL = service.suggestedConfigURL.deletingLastPathComponent()
    panel.canCreateDirectories = true
    panel.allowedContentTypes = [tomlContentType]

    guard panel.runModal() == .OK, let url = panel.url else { return }

    do {
      try service.export(to: url)
      lastConfigURL = url
      resultIssues = []
      resultMessage = L10n.PreferencesAdvanced.exported(url.path)
    } catch {
      resultIssues = [SnapzyConfigurationIssue(severity: .error, message: error.localizedDescription)]
      resultMessage = L10n.PreferencesAdvanced.exportFailed
    }
  }

  private func importConfig() {
    let panel = NSOpenPanel()
    panel.title = L10n.PreferencesAdvanced.importPanelTitle
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [tomlContentType]

    guard panel.runModal() == .OK, let url = panel.url else { return }

    do {
      let result = try service.import(from: url)
      lastConfigURL = url
      resultIssues = result.issues
      resultMessage = summary(for: result)
    } catch {
      resultIssues = [SnapzyConfigurationIssue(severity: .error, message: error.localizedDescription)]
      resultMessage = L10n.PreferencesAdvanced.importFailed
    }
  }

  private func summary(for result: SnapzyConfigurationImportResult) -> String {
    if result.hasErrors {
      return L10n.PreferencesAdvanced.importFailedWithErrors(
        result.issues.filter { $0.severity == .error }.count
      )
    }
    if result.issues.isEmpty {
      return L10n.PreferencesAdvanced.imported(result.appliedChangeCount)
    }
    return L10n.PreferencesAdvanced.importedWithWarnings(
      result.appliedChangeCount,
      result.issues.count
    )
  }

  private func openConfigFile() {
    let url = lastConfigURL ?? service.suggestedConfigURL

    if NSWorkspace.shared.open(url) {
      resultIssues = []
      resultMessage = L10n.PreferencesAdvanced.openedConfig(url.path)
      return
    }

    let fileExists = FileManager.default.fileExists(atPath: url.path)
    resultIssues = [
      SnapzyConfigurationIssue(
        severity: fileExists ? .error : .warning,
        message: fileExists
          ? L10n.PreferencesAdvanced.openConfigFailed(url.path)
          : L10n.PreferencesAdvanced.openConfigMissing(url.path)
      )
    ]
    resultMessage = L10n.PreferencesAdvanced.openConfigUnavailable
  }
}

private struct AdvancedResultSummaryRow: View {
  let message: String
  let severity: SnapzyConfigurationIssueSeverity?

  var body: some View {
    Label(message, systemImage: icon)
      .fontWeight(.medium)
      .foregroundStyle(color)
      .padding(.vertical, 3)
  }

  private var icon: String {
    switch severity {
    case .error:
      return "xmark.circle.fill"
    case .warning:
      return "exclamationmark.triangle.fill"
    case nil:
      return "checkmark.circle.fill"
    }
  }

  private var color: Color {
    switch severity {
    case .error:
      return .red
    case .warning:
      return .orange
    case nil:
      return .secondary
    }
  }
}

private struct AdvancedResultIssueGroup: View {
  let title: String
  let icon: String
  let color: Color
  let issues: [SnapzyConfigurationIssue]

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Label(title, systemImage: icon)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(color)

      ForEach(issues) { issue in
        HStack(alignment: .top, spacing: 6) {
          Circle()
            .fill(color)
            .frame(width: 5, height: 5)
            .padding(.top, 6)

          Text(issue.message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
      }
    }
    .padding(.vertical, 5)
  }
}

#Preview {
  AdvancedSettingsView()
    .frame(width: 600, height: 450)
}
