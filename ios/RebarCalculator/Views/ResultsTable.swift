import SwiftUI

/// 7 行 3 列的结果表格，行高按可用高度等分（最后一行占 2 份），
/// 对应 Android 横屏 TableLayout 的 weight=1/1/1/1/1/1/2。
struct ResultTable: View {
    let result22: StandardResult
    let result07: StandardResult

    var body: some View {
        GeometryReader { proxy in
            let unit = max(1, proxy.size.height / 8)
            VStack(spacing: 0) {
                row("项目", "22G101（结构图集）", "07FG（人防图集）", height: unit, header: true)
                row("抗震等级", result22.seismicLevel, result07.seismicLevel, height: unit)
                row("锚固倍数", number(result22.anchorMultiple, "d"), number(result07.anchorMultiple, "d"), height: unit)
                row("锚固长度", number(result22.anchorLength, "mm"), number(result07.anchorLength, "mm"), height: unit)
                row("搭接倍数", result22.lapFormula, result07.lapFormula, height: unit)
                row("搭接长度", number(result22.lapLength, "mm"), number(result07.lapLength, "mm"), height: unit)
                row("基本锚固\n修正系数\n四舍五入", result22.coefficientFormula, result07.coefficientFormula, height: unit * 2, last: true)
            }
        }
    }

    private func row(
        _ label: String,
        _ value22: String,
        _ value07: String,
        height: CGFloat,
        header: Bool = false,
        last: Bool = false
    ) -> some View {
        HStack(spacing: 0) {
            cell(
                label,
                bold: true,
                blue: false,
                fontSize: 11,
                header: header,
                last: last
            )
            .frame(width: 80)

            cell(
                value22,
                bold: header || last,
                blue: !header,
                fontSize: header ? 10.5 : (last ? 18 : 13),
                header: header,
                last: last
            )

            cell(
                value07,
                bold: header || last,
                blue: !header,
                fontSize: header ? 10.5 : (last ? 18 : 13),
                header: header,
                last: last
            )
        }
        .frame(height: height)
    }

    private func cell(
        _ text: String,
        bold: Bool,
        blue: Bool,
        fontSize: CGFloat,
        header: Bool,
        last: Bool
    ) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: bold ? .bold : .regular))
            .foregroundColor(blue ? AppTheme.blue600 : AppTheme.onSurface)
            .multilineTextAlignment(.center)
            .lineLimit(last ? 3 : 2)
            .minimumScaleFactor(header ? 0.7 : (last ? 0.45 : 0.7))
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .overlay(
                Rectangle().stroke(AppTheme.tableBorder, lineWidth: 0.8)
            )
    }

    private func number(_ value: Int?, _ unit: String) -> String {
        value.map { "\($0)\(unit)" } ?? "--"
    }
}
