import Foundation

extension String {
    /// "yyyy-MM-dd" 형식의 날짜 문자열을 Date로 변환
    func toDate(format: String = "yyyy-MM-dd") -> Date? {
        let f = DateFormatter()
        f.dateFormat = format
        return f.date(from: self)
    }

    /// "yyyy-MM" 형식의 연월 문자열을 Date로 변환 (월별 통계용)
    func toYearMonthDate() -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.date(from: self)
    }
}
