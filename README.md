# GLB Quick Look

macOS Quick Look extension for `.glb` (glTF Binary) 3D files.
Finder에서 `.glb` 파일을 선택하고 스페이스바를 누르면 3D 미리보기가 됩니다.

![macOS](https://img.shields.io/badge/macOS-15.0%2B-black)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- GLB v2 바이너리 파싱 (순수 Swift, 외부 의존성 없음)
- PBR 머티리얼 (base color, metallic, roughness, emissive)
- 노드 계층 구조 및 TRS/Matrix 변환
- 다중 프리미티브 메시 지원
- 마우스 드래그로 회전, 스크롤로 줌

## Install

### Homebrew (권장)

```bash
brew install --cask byunkyungmin/tap/glb-quicklook
```

### Manual

1. [Releases](https://github.com/byunkyungmin/glb-quicklook/releases/latest)에서 `GLBQuickLook.zip` 다운로드
2. 압축 해제 후 `GLBQuickLook.app`을 `/Applications` 또는 `~/Applications`로 이동

> 앱을 실행할 필요 없습니다. 설치만 하면 시스템이 Quick Look 확장을 자동 등록합니다.

### Build from source

```bash
git clone https://github.com/byunkyungmin/glb-quicklook.git
cd glb-quicklook
make install
```

Xcode가 설치되어 있어야 합니다.

## Usage

1. Finder에서 `.glb` 파일 선택
2. 스페이스바
3. 마우스 드래그로 회전, 스크롤로 줌 인/아웃

## Uninstall

```bash
brew uninstall glb-quicklook
```

또는 수동으로:

```bash
rm -rf ~/Applications/GLBQuickLook.app
# 또는
rm -rf /Applications/GLBQuickLook.app
```

## Architecture

```
GLBQuickLook.app
├── Contents/MacOS/GLBQuickLook          # 호스트 앱 (껍데기)
└── Contents/PlugIns/
    └── PreviewExtension.appex           # Quick Look 확장 (핵심)
        ├── PreviewViewController.swift  # QLPreviewingController
        └── GLBParser.swift              # GLB → SceneKit 변환
```

호스트 앱은 macOS App Extension 정책상 필요한 컨테이너이며, 실제 동작은 `.appex` 확장이 담당합니다.

## License

MIT
