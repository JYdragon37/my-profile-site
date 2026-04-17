import SwiftData
import Foundation

// MARK: - ModelContext 전역 접근 헬퍼
// ⚠️ SwiftUI View 내부에서는 반드시 @Environment(\.modelContext)를 사용하세요.
// 이 클래스는 View 외부(ViewModel 초기화 등)에서만 사용합니다.
// NinetyNineApp.swift의 sharedModelContainer와 동일한 컨테이너를 공유합니다.
final class ModelContextProvider {

    // NinetyNineApp에서 생성한 컨테이너를 주입받아 공유
    static var container: ModelContainer?

    static var shared: ModelContext {
        guard let container else {
            // 앱 시작 전 container가 설정되지 않은 경우 (테스트 등)
            fatalError("ModelContextProvider.container가 초기화되지 않았습니다. NinetyNineApp에서 setup()을 호출하세요.")
        }
        return ModelContext(container)
    }

    static func setup(with container: ModelContainer) {
        self.container = container
    }
}
