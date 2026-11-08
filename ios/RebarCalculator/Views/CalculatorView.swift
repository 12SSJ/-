import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var toast = ToastCenter()

    @State private var rebarIndex = 1
    @State private var diameterIndex = 7
    @State private var seismicIndex = 2
    @State private var concreteIndex = 2
    @State private var jointIndex = 1
    @State private var protectionIndex = 0
    @State private var epoxyIndex = 0
    @State private var disturbanceIndex = 0
    @State private var selectedTab = 0
    @State private var showingNotes = false

    private static let engine = CalculationEngine()

    private static let rebarTypes = ["HPB300", "HRB400/HRBF/RRB", "HRB500/HRBF500", "HPB235（人防）", "HRB335（人防）"]
    private static let diameterValues = [6, 8, 10, 12, 14, 16, 18, 20, 22, 25, 28, 30, 32, 36, 40, 50]
    private static let diameterOptions = diameterValues.map { String($0) }
    private static let seismicLevels = ["一级", "二级", "三级", "四级"]
    private static let concreteGrades = ["C20", "C25", "C30", "C35", "C40", "C45", "C50", "C55", "C60"]
    private static let jointRates = ["25%", "50%", "100%"]
    private static let protections = ["小于3d", "3d~5d", "大于5d"]
    private static let yesNo = ["否", "是"]

    private var input: CalculationInput {
        CalculationInput(
            rebarType: Self.rebarTypes[rebarIndex],
            diameter: Self.diameterValues[diameterIndex],
            seismicLevel: Self.seismicLevels[seismicIndex],
            concreteGrade: Self.concreteGrades[concreteIndex],
            jointRate: Int(Self.jointRates[jointIndex].replacingOccurrences(of: "%", with: "")) ?? 50,
            protectionLayer: Self.protections[protectionIndex],
            epoxyCoating: epoxyIndex == 1,
            constructionDisturbance: disturbanceIndex == 1
        )
    }

    private var results: (StandardResult, StandardResult) {
        (Self.engine.calculate22G101(input), Self.engine.calculate07FG01(input))
    }

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            VStack(spacing: 0) {
                header
                if isLandscape {
                    HStack(spacing: 0) {
                        formPanel(compact: true)
                            .frame(width: proxy.size.width * 0.44)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .background(Color.white)
                        rightPanel
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        formPanel(compact: false)
                        tabBar
                        contentPanel
                    }
                }
            }
            .background(AppTheme.surface)
        }
        .sheet(isPresented: $showingNotes) {
            NotesRootView()
        }
        .toast(toast.message)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Menu {
                Button {
                    showingNotes = true
                } label: {
                    Label("记事本", systemImage: "note.text")
                }
                Button(role: .destructive) {
                    appState.logout()
                } label: {
                    Label("返回登录页", systemImage: "person.crop.circle.badge.xmark")
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.blue600)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(AppTheme.headerBackground)
    }

    // MARK: - Form

    private func formPanel(compact: Bool) -> some View {
        let rowHeight: CGFloat = compact ? 26 : 30
        return VStack(spacing: 0) {
            formRow("钢筋种类：", height: rowHeight) {
                optionPicker($rebarIndex, Self.rebarTypes)
            }
            formRow("钢筋直径（mm）：", height: rowHeight) {
                optionPicker($diameterIndex, Self.diameterOptions)
                Text(RebarWeightRepository.weight(for: Self.diameterValues[diameterIndex]) + "kg/米")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x526B82))
                    .frame(width: compact ? 82 : 88, alignment: .trailing)
            }
            formRow("抗震等级：", height: rowHeight) {
                optionPicker($seismicIndex, Self.seismicLevels)
            }
            formRow("砼强度：", height: rowHeight) {
                optionPicker($concreteIndex, Self.concreteGrades)
            }
            formRow("接头率：", height: rowHeight) {
                optionPicker($jointIndex, Self.jointRates)
            }
            formRow("保护层厚度：", height: rowHeight) {
                optionPicker($protectionIndex, Self.protections)
            }
            formRow("环氧树脂涂层带肋：", height: rowHeight) {
                optionPicker($epoxyIndex, Self.yesNo)
            }
            formRow("施工易受扰动：", height: rowHeight) {
                optionPicker($disturbanceIndex, Self.yesNo)
            }

            Button(action: reset) {
                Text("恢复默认修正系数")
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 28 : 30)
                    .background(AppTheme.blue600)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            Text("注：当人防区为一级抗震，Laf与Lae取大值，即Laf=Lae；\n当为四级抗震，人防区取Laf；即Laf=1.05La。")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: compact ? 34 : 44)
        }
        .padding(.horizontal, 6)
        .background(Color.white)
    }

    private func formRow<Content: View>(
        _ title: String,
        height: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.blue800)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: 108, alignment: .leading)
            content()
        }
        .frame(height: height)
    }

    private func optionPicker(_ selection: Binding<Int>, _ options: [String]) -> some View {
        Picker("", selection: selection) {
            ForEach(options.indices, id: \.self) { index in
                Text(options[index]).tag(index)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .tint(AppTheme.onSurface)
        .font(.system(size: 13))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reset() {
        rebarIndex = 1
        diameterIndex = 7
        seismicIndex = 2
        concreteIndex = 2
        jointIndex = 1
        protectionIndex = 0
        epoxyIndex = 0
        disturbanceIndex = 0
    }

    // MARK: - Tabs and content

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton("计算结果", index: 0)
            tabButton("计算原理", index: 1)
        }
        .frame(height: 38)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xDDE4ED))
                .frame(height: 0.5)
        }
    }

    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(selectedTab == index ? AppTheme.blue600 : Color(hex: 0x4072A8))
                Rectangle()
                    .fill(selectedTab == index ? AppTheme.blue600 : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var contentPanel: some View {
        if selectedTab == 0 {
            resultsPanel
        } else {
            TheoryView()
        }
    }

    private var rightPanel: some View {
        VStack(spacing: 0) {
            tabBar
            contentPanel
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.white)
    }

    private var resultsPanel: some View {
        let output = results
        return VStack(spacing: 0) {
            Text("锚固搭接计算结果")
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(AppTheme.resultHeader)

            ResultTable(result22: output.0, result07: output.1)

            Text("联系方式：19198975200")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .frame(height: 20)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
