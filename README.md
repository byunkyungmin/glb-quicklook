# GLB Quick Look

macOS Quick Look extension for `.glb` (glTF Binary) 3D files.
Select a `.glb` file in Finder and press Space to preview 3D models.

[한국어](README.ko.md)

![macOS](https://img.shields.io/badge/macOS-15.0%2B-black)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- GLB v2 binary parsing (pure Swift, zero dependencies)
- PBR materials (base color, metallic, roughness, emissive)
- Node hierarchy with TRS/Matrix transforms
- Multi-primitive mesh support
- Mouse drag to orbit, scroll to zoom

## Install

### Homebrew (recommended)

```bash
brew install --cask byunkyungmin/tap/glb-quicklook
```

### Manual

1. Download `GLBQuickLook.zip` from [Releases](https://github.com/byunkyungmin/glb-quicklook/releases/latest)
2. Unzip and move `GLBQuickLook.app` to `/Applications` or `~/Applications`

> No need to launch the app. The system automatically registers the Quick Look extension once installed.

### Build from source

```bash
git clone https://github.com/byunkyungmin/glb-quicklook.git
cd glb-quicklook
make install
```

Requires Xcode.

## Usage

1. Select a `.glb` file in Finder
2. Press Space
3. Drag to rotate, scroll to zoom in/out

## Uninstall

```bash
brew uninstall glb-quicklook
```

Or manually:

```bash
rm -rf ~/Applications/GLBQuickLook.app
# or
rm -rf /Applications/GLBQuickLook.app
```

## Architecture

```
GLBQuickLook.app
├── Contents/MacOS/GLBQuickLook          # Host app (shell)
└── Contents/PlugIns/
    └── PreviewExtension.appex           # Quick Look extension (core)
        ├── PreviewViewController.swift  # QLPreviewingController
        └── GLBParser.swift              # GLB → SceneKit
```

The host app is a container required by macOS App Extension policy. The actual work is done by the `.appex` extension.

## License

MIT
