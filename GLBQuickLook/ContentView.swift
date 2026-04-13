import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("GLB Quick Look")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Finder에서 .glb 파일을 선택하고\n스페이스바를 눌러 3D 미리보기를 할 수 있습니다.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 200)

            VStack(alignment: .leading, spacing: 12) {
                Label("이 앱을 /Applications로 이동하세요", systemImage: "1.circle.fill")
                Label("앱 실행은 불필요 — 시스템이 자동 등록합니다", systemImage: "2.circle.fill")
                Label("Finder에서 .glb 파일 선택 후 스페이스바", systemImage: "3.circle.fill")
            }
            .font(.body)
            .foregroundStyle(.secondary)
        }
        .padding(48)
        .frame(width: 420, height: 380)
    }
}
