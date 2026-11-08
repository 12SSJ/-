import Foundation

/// 图集查表数据，与计算逻辑隔离，便于日后核对或更新规范。
enum ChartRepository {
    private static let base22G: [String: [String: Int]] = {
        let grades = ["C25", "C30", "C35", "C40", "C45", "C50", "C55", "C60"]
        func row(_ values: [Int]) -> [String: Int] {
            var map: [String: Int] = [:]
            for (index, grade) in grades.enumerated() {
                map[grade] = values[index]
            }
            return map
        }
        return [
            "HPB300": row([34, 30, 28, 25, 24, 23, 22, 21]),
            "HRB400/HRBF400/RRB400": row([40, 35, 32, 29, 28, 27, 26, 25]),
            "HRB500/HRBF500": row([48, 43, 39, 36, 34, 32, 31, 30])
        ]
    }()

    private static let civilAnchor = makeCivil([
        "HPB235": [[33, 33], [28, 28], [25, 25], [23, 23], [21, 21]],
        "HRB335": [[41, 45], [35, 39], [31, 34], [29, 31], [26, 29]],
        "HRB400": [[49, 53], [42, 46], [37, 41], [34, 38], [31, 34]]
    ])

    private static let civilLap25 = makeCivil([
        "HPB235": [[39, 39], [34, 34], [30, 30], [27, 27], [25, 25]],
        "HRB335": [[48, 53], [42, 47], [37, 41], [34, 38], [31, 35]],
        "HRB400": [[58, 64], [50, 55], [45, 50], [41, 46], [37, 41]]
    ])

    private static let civilLap50 = makeCivil([
        "HPB235": [[45, 45], [39, 39], [35, 35], [32, 32], [29, 29]],
        "HRB335": [[56, 62], [49, 54], [43, 48], [40, 44], [36, 40]],
        "HRB400": [[68, 75], [59, 65], [52, 58], [48, 52], [44, 48]]
    ])

    static func find22G(rebar: String, concrete: String) -> Int? {
        base22G[rebar]?[concrete]
    }

    static func findCivilAnchor(rebar: String, concrete: String, diameterOver25: Bool) -> Int? {
        find(civilAnchor, rebar: rebar, concrete: concrete, diameterOver25: diameterOver25)
    }

    static func findCivilLap(rebar: String, concrete: String, diameterOver25: Bool, jointRate: Int) -> Int? {
        if jointRate <= 25 { return find(civilLap25, rebar: rebar, concrete: concrete, diameterOver25: diameterOver25) }
        if jointRate <= 50 { return find(civilLap50, rebar: rebar, concrete: concrete, diameterOver25: diameterOver25) }
        return nil
    }

    private static func find(
        _ table: [String: [String: [String: Int]]],
        rebar: String,
        concrete: String,
        diameterOver25: Bool
    ) -> Int? {
        table[rebar]?[concrete]?[diameterOver25 ? "d>25" : "d<=25"]
    }

    private static func makeCivil(_ rows: [String: [[Int]]]) -> [String: [String: [String: Int]]] {
        let grades = ["C20", "C25", "C30", "C35", "C40"]
        var table: [String: [String: [String: Int]]] = [:]
        for (rebar, values) in rows {
            var gradeMap: [String: [String: Int]] = [:]
            for (index, grade) in grades.enumerated() where index < values.count {
                gradeMap[grade] = [
                    "d<=25": values[index][0],
                    "d>25": values[index][1]
                ]
            }
            table[rebar] = gradeMap
        }
        return table
    }
}
