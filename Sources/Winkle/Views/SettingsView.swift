import SwiftUI

/// Réglages — design signature : carte glass sur le fond navy periwinkle,
/// contrôles maison (segmented, toggles) plutôt que le Form natif.
struct SettingsView: View {
    @ObservedObject var prefs = Preferences.shared

    var body: some View {
        ZStack {
            WinkleBackground(mouse: CGPoint(x: 0.5, y: 0.35))
                .overlay(Color.black.opacity(0.12))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    rhythmGroup
                    awayGroup
                    displayGroup
                    behaviorGroup
                    exceptionsGroup
                    appearanceGroup
                    Divider().overlay(Color.white.opacity(0.08))
                    footer
                }
                .padding(30)
                .frame(width: 600, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color(red: 0.078, green: 0.11, blue: 0.20).opacity(0.55))
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                )
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 660, height: 700)
        .preferredColorScheme(.dark)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            WinkleEye(size: 30, lineWidth: 4)
            Text(L10n.t("settings.title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(WinkleStyle.ink)
        }
    }

    // MARK: Rythme

    private var rhythmGroup: some View {
        SettingGroup(label: L10n.t("settings.rhythm")) {
            SettingRow(title: L10n.t("settings.cadence"),
                       description: L10n.t("settings.cadenceDesc")) {
                WinkleSegmented(
                    options: Preset.allCases.map { ($0, $0.label) },
                    selection: presetBinding
                )
            }
            if prefs.preset == .custom {
                sliderRow(title: L10n.t("settings.frequency"),
                          description: L10n.t("settings.frequencyDesc"),
                          value: intBinding(\.customWorkMinutes),
                          range: 5...60, unit: L10n.t("settings.min"))
                sliderRow(title: L10n.t("settings.duration"),
                          description: L10n.t("settings.durationDesc"),
                          value: intBinding(\.customPauseSeconds),
                          range: 10...60, unit: L10n.t("settings.sec"))
            }
        }
    }

    // MARK: Absence

    private var awayGroup: some View {
        SettingGroup(label: L10n.t("settings.away")) {
            sliderRow(title: L10n.t("settings.idleReset"),
                      description: L10n.t("settings.idleResetDesc"),
                      value: intBinding(\.idleResetSeconds),
                      range: 30...600, step: 30, unit: L10n.t("settings.sec"))
        }
    }

    // MARK: Affichage

    private var displayGroup: some View {
        SettingGroup(label: L10n.t("settings.display")) {
            SettingRow(title: L10n.t("settings.style")) {
                WinkleSegmented(
                    options: [
                        (DisplayMode.overlay, L10n.t("settings.styleOverlay")),
                        (DisplayMode.notification, L10n.t("settings.styleNotif")),
                        (DisplayMode.both, L10n.t("settings.styleBoth")),
                    ],
                    selection: displayModeBinding
                )
            }
            SettingRow(title: L10n.t("settings.preAlert"),
                       description: L10n.t("settings.preAlertDesc")) {
                WinkleToggle(isOn: $prefs.preAlertEnabled)
            }
            SettingRow(title: L10n.t("settings.allScreens")) {
                WinkleToggle(isOn: $prefs.allScreens)
            }
        }
    }

    // MARK: Comportement

    private var behaviorGroup: some View {
        SettingGroup(label: L10n.t("settings.behavior")) {
            SettingRow(title: L10n.t("settings.mode"),
                       description: L10n.t("settings.modeDesc")) {
                WinkleSegmented(
                    options: [
                        (false, L10n.t("settings.modeSoft")),
                        (true, L10n.t("settings.modeStrict")),
                    ],
                    selection: $prefs.strictMode
                )
            }
            SettingRow(title: L10n.t("settings.sound")) {
                WinkleToggle(isOn: $prefs.soundEnabled)
            }
            SettingRow(title: L10n.t("settings.launchAtLogin")) {
                WinkleToggle(isOn: launchAtLoginBinding)
            }
            SettingRow(title: L10n.t("settings.respectDND")) {
                WinkleToggle(isOn: $prefs.respectDoNotDisturb)
            }
        }
    }

    // MARK: Exceptions

    private var exceptionsGroup: some View {
        SettingGroup(label: L10n.t("settings.exceptions")) {
            SettingRow(title: L10n.t("settings.suspendCamera")) {
                WinkleToggle(isOn: $prefs.suspendOnCamera)
            }
            SettingRow(title: L10n.t("settings.suspendFullscreen")) {
                WinkleToggle(isOn: $prefs.suspendOnFullscreen)
            }
            whitelistRow
        }
    }

    private var whitelistRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("settings.exceptionsDesc"))
                .font(.system(size: 12))
                .foregroundColor(WinkleStyle.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            if prefs.whitelistApps.isEmpty {
                Text(L10n.t("settings.noApps"))
                    .font(.system(size: 12.5))
                    .foregroundColor(WinkleStyle.inkFaint)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(prefs.whitelistApps, id: \.self) { app in
                        appChip(app)
                    }
                }
            }

            Button(action: addApp) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(L10n.t("settings.addApp"))
                }
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(WinkleStyle.inkDim)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .overlay(
                    Capsule().stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundColor(Color.white.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
    }

    private func appChip(_ bundleID: String) -> some View {
        HStack(spacing: 6) {
            Text(AppInfo.displayName(forBundleID: bundleID))
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(WinkleStyle.ink)
            Button {
                prefs.whitelistApps.removeAll { $0 == bundleID }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(WinkleStyle.inkDim)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(WinkleStyle.peri.opacity(0.16))
                .overlay(Capsule().stroke(WinkleStyle.peri.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: Apparence & langue

    private var appearanceGroup: some View {
        SettingGroup(label: L10n.t("settings.appearance")) {
            SettingRow(title: L10n.t("settings.theme")) {
                WinkleSegmented(
                    options: [
                        (AppTheme.light, L10n.t("settings.themeLight")),
                        (AppTheme.dark, L10n.t("settings.themeDark")),
                        (AppTheme.auto, L10n.t("settings.themeAuto")),
                    ],
                    selection: themeBinding
                )
            }
            SettingRow(title: L10n.t("settings.languageLabel")) {
                WinkleSegmented(
                    options: [(AppLanguage.fr, "Français"), (AppLanguage.en, "English")],
                    selection: languageBinding
                )
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Text("\(L10n.t("settings.footer")) · v\(appVersion)")
                .font(.system(size: 12))
                .foregroundColor(WinkleStyle.inkFaint)
            Spacer()
            Button(action: openDonate) {
                Text(L10n.t("settings.donate"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(WinkleStyle.ink)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 18)
                    .background(
                        Capsule()
                            .fill(WinkleStyle.peri.opacity(0.16))
                            .overlay(Capsule().stroke(WinkleStyle.peri.opacity(0.3), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    // MARK: - Rangée slider

    private func sliderRow(
        title: String, description: String,
        value: Binding<Double>, range: ClosedRange<Double>,
        step: Double = 1, unit: String
    ) -> some View {
        SettingRow(title: title, description: description) {
            HStack(spacing: 12) {
                Slider(value: value, in: range, step: step)
                    .tint(WinkleStyle.peri)
                    .frame(width: 150)
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(WinkleStyle.periSoft)
                    .monospacedDigit()
                    .frame(width: 54, alignment: .trailing)
            }
        }
    }

    // MARK: - Actions

    private func addApp() {
        if let bundleID = AppInfo.pickApplication() {
            var apps = prefs.whitelistApps
            if !apps.contains(bundleID) { apps.append(bundleID) }
            prefs.whitelistApps = apps
        }
    }

    private func openDonate() {
        if let url = URL(string: "https://buymeacoffee.com/julesbertolino") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Bindings

    private var presetBinding: Binding<Preset> {
        Binding(get: { prefs.preset }, set: { prefs.preset = $0 })
    }
    private var displayModeBinding: Binding<DisplayMode> {
        Binding(get: { prefs.displayMode }, set: { prefs.displayMode = $0 })
    }
    private var themeBinding: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: prefs.themeRaw) ?? .auto },
            set: { prefs.themeRaw = $0.rawValue; applyTheme($0) }
        )
    }
    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { prefs.language }, set: { prefs.language = $0 })
    }
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { prefs.launchAtLogin },
            set: { enabled in
                prefs.launchAtLogin = enabled
                LoginItem.set(enabled)
            }
        )
    }

    private func intBinding(_ keyPath: ReferenceWritableKeyPath<Preferences, Int>) -> Binding<Double> {
        Binding(
            get: { Double(prefs[keyPath: keyPath]) },
            set: { prefs[keyPath: keyPath] = Int($0) }
        )
    }

    private func applyTheme(_ theme: AppTheme) {
        switch theme {
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:  NSApp.appearance = NSAppearance(named: .darkAqua)
        case .auto:  NSApp.appearance = nil
        }
    }
}

// MARK: - FlowLayout

/// Disposition en flux (les chips passent à la ligne quand la largeur est atteinte).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            rows[rows.count - 1].append(subview)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
