import Foundation

/// 一套图集的完整计算结果。
struct StandardResult {
    let standardName: String
    let seismicLevel: String
    let coefficientFormula: String
    let anchorMultiple: Int?
    let anchorLength: Int?
    let lapFormula: String
    let lapMultiple: Int?
    let lapLength: Int?

    static func unavailable(_ name: String, _ note: String) -> StandardResult {
        StandardResult(
            standardName: name,
            seismicLevel: "--",
            coefficientFormula: note,
            anchorMultiple: nil,
            anchorLength: nil,
            lapFormula: note,
            lapMultiple: nil,
            lapLength: nil
        )
    }

    static func make(
        name: String,
        seismic: String,
        coefficientFormula: String,
        anchorMultiple: Int,
        anchorLength: Int,
        lapFormula: String,
        lapMultiple: Int,
        lapLength: Int
    ) -> StandardResult {
        StandardResult(
            standardName: name,
            seismicLevel: seismic,
            coefficientFormula: coefficientFormula,
            anchorMultiple: anchorMultiple,
            anchorLength: anchorLength,
            lapFormula: lapFormula,
            lapMultiple: lapMultiple,
            lapLength: lapLength
        )
    }
}
