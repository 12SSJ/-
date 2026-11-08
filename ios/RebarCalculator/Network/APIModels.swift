import Foundation

/// 后台统一响应结构：code = 0 表示成功。
struct Envelope<T: Decodable>: Decodable {
    let code: Int
    let message: String?
    let data: T?
}

struct EmptyData: Decodable {}

struct TokenPayload: Decodable {
    let token: String
}

struct NoteItem: Decodable, Identifiable, Hashable {
    let id: Int64
    let title: String?
    let content: String?
}
