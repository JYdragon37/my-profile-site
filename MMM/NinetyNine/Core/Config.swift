// MARK: - Config.swift
// 키값이 필요한 모든 설정을 이 파일 한 곳에서 관리합니다.
// 나중에 이 파일만 수정하면 앱 전체에 반영됩니다.

import Foundation

enum Config {

    // MARK: - Google Sheets
    // 구글 시트 URL에서 /d/{여기}/edit 값을 복사해서 붙여넣으세요.
    static let googleSheetID = "1ohLSDyrfskjL7UMuhrKrvrSFb_h8YPvjtqOBOomFzv0"
    static var motivationSheetURL: URL {
        URL(string: "https://docs.google.com/spreadsheets/d/\(googleSheetID)/export?format=csv&gid=0")!
    }

    // MARK: - Firebase Storage
    // Firebase Console > Storage > 버킷 이름 (예: gs://your-app.appspot.com)
    static let firebaseStorageBucket = "ninetynine-4c11e.firebasestorage.app"
    static let motivationImageFolder = "alarm-images"

    // MARK: - Challenge Timer
    // 브랜드: "99분 챌린지" / 실제 타이머: 199분
    static let challengeBrandName = "99분 챌린지"
    static let challengeTotalSeconds = 199 * 60  // 199분
    static let flowTimerSeconds = 3 * 60         // 착착 3분
    static let deepTimerSeconds = 30 * 60        // 몰입 30분

    // MARK: - Motivation Fetch
    // 구글 시트 fetch 주기 (시간 단위)
    static let motivationFetchIntervalHours: Double = 24

    // MARK: - Streak Milestones
    static let streakMilestoneDays = [7, 14, 21, 30, 60, 100]

    // MARK: - Onboarding Template
    // RoutineTemplates.json에서 기본 템플릿 ID
    static let defaultTemplateID = "general"
}
