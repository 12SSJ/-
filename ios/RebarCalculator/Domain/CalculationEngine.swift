import Foundation

/// 规范公式和取整规则的唯一实现位置，逐行对应 Android CalculationEngine。
struct CalculationEngine {
    func calculate22G101(_ input: CalculationInput) -> StandardResult {
        guard let chartRebar = to22GRebar(input.rebarType),
              input.concreteGrade != "C20",
              let chartBase = ChartRepository.find22G(rebar: chartRebar, concrete: input.concreteGrade) else {
            return .unavailable("22G101 结构图集", "22G 表无")
        }

        let base = input.diameter > 25 ? roundHalfUp(Double(chartBase) * 1.1) : chartBase
        let seismic = seismicCoefficient(input.seismicLevel)
        let protection = protectionCoefficient(input.protectionLayer)
        let epoxy = input.epoxyCoating ? 1.25 : 1
        let disturbance = input.constructionDisturbance ? 1.1 : 1
        let anchorMultiple = roundHalfUp(Double(base) * seismic * protection * epoxy * disturbance)
        let anchorLength = anchorMultiple * input.diameter
        let joint = jointCoefficient(input.jointRate)
        let lapMultiple = roundHalfUp(Double(anchorMultiple) * joint)
        let lapLength = lapMultiple * input.diameter

        var formula = input.diameter > 25 ? "\(chartBase)×1.1=\(base)" : "\(base)"
        formula += factor(seismic) + factor(protection) + factor(epoxy) + factor(disturbance)

        return .make(
            name: "22G101 结构图集",
            seismic: input.seismicLevel,
            coefficientFormula: formula,
            anchorMultiple: anchorMultiple,
            anchorLength: anchorLength,
            lapFormula: "\(anchorMultiple)×\(joint)=\(lapMultiple)d",
            lapMultiple: lapMultiple,
            lapLength: lapLength
        )
    }

    func calculate07FG01(_ input: CalculationInput) -> StandardResult {
        guard let chartRebar = toCivilRebar(input.rebarType) else {
            return .unavailable("07FG01 人防图集", "人防表无")
        }
        let concrete = normalizeCivilConcrete(input.concreteGrade)
        let over25 = input.diameter > 25
        guard let anchorMultiple = ChartRepository.findCivilAnchor(rebar: chartRebar, concrete: concrete, diameterOver25: over25) else {
            return .unavailable("07FG01 人防图集", "人防表无")
        }

        let tableLap = ChartRepository.findCivilLap(rebar: chartRebar, concrete: concrete, diameterOver25: over25, jointRate: input.jointRate)
        let lapMultiple = tableLap ?? roundHalfUp(Double(anchorMultiple) * jointCoefficient(input.jointRate))
        // 原 Python 在 25%/50% 人防表命中时只显示“52d”，不附加任何说明文字。
        let lapFormula = tableLap == nil
            ? "\(anchorMultiple)×\(jointCoefficient(input.jointRate))=\(lapMultiple)d"
            : "\(lapMultiple)d"

        return .make(
            name: "07FG01 人防图集",
            seismic: "三级",
            coefficientFormula: "人防表：\(anchorMultiple)d",
            anchorMultiple: anchorMultiple,
            anchorLength: anchorMultiple * input.diameter,
            lapFormula: lapFormula,
            lapMultiple: lapMultiple,
            lapLength: lapMultiple * input.diameter
        )
    }

    private func to22GRebar(_ rebar: String) -> String? {
        switch rebar {
        case "HPB300": return "HPB300"
        case "HRB400/HRBF/RRB": return "HRB400/HRBF400/RRB400"
        case "HRB500/HRBF500": return "HRB500/HRBF500"
        default: return nil
        }
    }

    private func toCivilRebar(_ rebar: String) -> String? {
        switch rebar {
        case "HPB235（人防）": return "HPB235"
        case "HRB335（人防）": return "HRB335"
        case "HRB400/HRBF/RRB": return "HRB400"
        default: return nil
        }
    }

    private func normalizeCivilConcrete(_ grade: String) -> String {
        ["C20", "C25", "C30", "C35", "C40"].contains(grade) ? grade : "C40"
    }

    private func seismicCoefficient(_ level: String) -> Double {
        if level == "一级" || level == "二级" { return 1.15 }
        if level == "三级" { return 1.05 }
        return 1
    }

    private func protectionCoefficient(_ protection: String) -> Double {
        if protection == "3d~5d" { return 0.8 }
        if protection == "大于5d" { return 0.7 }
        return 1
    }

    private func jointCoefficient(_ rate: Int) -> Double {
        if rate == 25 { return 1.2 }
        if rate == 50 { return 1.4 }
        return 1.6
    }

    /// 对应 Java BigDecimal.valueOf(value).setScale(0, HALF_UP) 的十进制四舍五入。
    private func roundHalfUp(_ value: Double) -> Int {
        var source = Decimal(string: String(value)) ?? Decimal(0)
        var result = Decimal()
        NSDecimalRound(&result, &source, 0, .plain)
        return NSDecimalNumber(decimal: result).intValue
    }

    private func factor(_ value: Double) -> String {
        value == 1 ? "" : "×\(value)"
    }
}
