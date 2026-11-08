import SwiftUI

/// 与原 Python「计算原理」页一致的固定说明和 22G101 基本锚固表。
struct TheoryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Self.intro)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.onSurface)
                    .lineSpacing(3)

                theoryTable
                    .padding(.top, 4)

                Text(Self.details)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.onSurface)
                    .lineSpacing(3)
                    .padding(.top, 8)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
    }

    private var theoryTable: some View {
        VStack(spacing: 0) {
            tableRow(["C25", "C30", "C35", "C40"], header: true)
            tableRow(["34d", "30d", "28d", "25d"])
            tableRow(["40d", "35d", "32d", "29d"])
            tableRow(["48d", "43d", "39d", "36d"])
            tableRow(["C45", "C50", "C55", "C60"], header: true)
            tableRow(["24d", "23d", "22d", "21d"])
            tableRow(["28d", "27d", "26d", "25d"])
            tableRow(["34d", "32d", "31d", "30d"])
        }
    }

    private func tableRow(_ values: [String], header: Bool = false) -> some View {
        HStack(spacing: 0) {
            ForEach(values.indices, id: \.self) { index in
                Text(values[index])
                    .font(.system(size: 11, weight: header ? .bold : .regular))
                    .foregroundColor(AppTheme.onSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .background(Color.white)
                    .overlay(
                        Rectangle().stroke(AppTheme.tableBorder, lineWidth: 0.8)
                    )
            }
        }
    }

    private static let intro = """
    钢筋锚固与搭接长度计算原理

    一、基本计算公式
    锚固长度 = 基本锚固系数 × 修正系数 × 钢筋直径
    搭接长度 = 锚固长度 × 搭接系数

    二、22G101规范基本锚固lab：
    砼标号：
    HPB300
    HRB400/HRBF400/RRB400
    HRB500/HRBF500
    """

    private static let details = """
    抗震等级修正系数：
    • 一级抗震：1.15
    • 二级抗震：1.15
    • 三级抗震：1.05
    • 四级抗震：1.00

    直径修正（新增）：
    • 当直径>25mm时，基本锚固lab需先乘以1.1

    三、07FG01人防规范
    直接使用表格查找，没有则显示"人防表无"
    表格中包含：
    1. HPB235(人防) - 仅用于人防
    2. HRB335(人防) - 仅用于人防
    3. HRB400 - 可用于人防和22G101

    混凝土强度：C20、C25、C30、C35、C40
    直径分界：d≤25和d>25
    搭接接头面积：25%、50%

    注意：当选择HPB235(人防)或HRB335(人防)时，22G101结构图集结果为空

    四、搭接长度系数
    • 接头率25%：1.2倍
    • 接头率50%：1.4倍
    • 接头率100%：1.6倍

    五、其它修正系数：
    1. 保护层厚度修正：
       • 保护层厚度小于3d：修正系数1.0
       • 保护层厚度3d~5d： 修正系数0.8
       • 保护层厚度大于5d：修正系数0.7
    2. 环氧树脂涂层带肋：  修正系数1.25
    3. 施工过程中易受扰动：修正系数1.1

    六、计算步骤
    1. 根据钢筋种类、砼强度确定基础锚固系数
    2. 当直径>25mm时，基础锚固系数乘以1.1并四舍五入取整
    3. 判断抗震等级修正系数
    4. 判断保护层厚度修正系数
    5. 判断环氧树脂涂层修正
    6. 判断施工扰动修正
    7. 计算最终锚固长度，结果四舍五入
    8. 判断接头率计算搭接长度：
       用第7步取整结果×搭接系数，结果四舍五入

    七、人防规范计算
    1. 将输入参数映射到人防表格
    2. 直接在表格中查找对应值
    3. 如果找不到（如HRB500、HPB300），显示"人防表无"
    4. 人防规范不考虑保护层、环氧涂层、施工扰动等修正系数
    """
}
