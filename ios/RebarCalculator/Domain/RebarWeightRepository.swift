import Foundation

/// 钢筋理论重量（kg/m），用于与原界面一致的直径旁提示。
enum RebarWeightRepository {
    private static let weights: [Int: String] = [
        6: "0.222", 8: "0.395", 10: "0.617", 12: "0.888", 14: "1.21",
        16: "1.58", 18: "2.00", 20: "2.47", 22: "2.98", 25: "3.85",
        28: "4.83", 30: "5.549", 32: "6.31", 36: "7.99", 40: "9.87",
        50: "15.42"
    ]

    static func weight(for diameter: Int) -> String {
        weights[diameter] ?? "--"
    }
}
