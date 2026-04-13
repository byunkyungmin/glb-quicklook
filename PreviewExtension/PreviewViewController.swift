import Cocoa
import Quartz
import SceneKit

class PreviewViewController: NSViewController, QLPreviewingController {

    private var scnView: ZoomableSCNView!

    override func loadView() {
        scnView = ZoomableSCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        self.view = scnView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let parser = GLBParser()
            let scene = try parser.parse(url: url)

            setupCamera(for: scene)
            setupLighting(for: scene)

            scnView.scene = scene

            handler(nil)
        } catch {
            handler(error)
        }
    }

    private func setupCamera(for scene: SCNScene) {
        let (minVec, maxVec) = scene.rootNode.boundingBox

        let center = simd_float3(
            Float((minVec.x + maxVec.x) / 2),
            Float((minVec.y + maxVec.y) / 2),
            Float((minVec.z + maxVec.z) / 2)
        )
        let size = simd_float3(
            Float(maxVec.x - minVec.x),
            Float(maxVec.y - minVec.y),
            Float(maxVec.z - minVec.z)
        )
        let maxDim = max(size.x, max(size.y, size.z))

        guard maxDim > 0 else { return }

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.automaticallyAdjustsZRange = true
        cameraNode.camera?.fieldOfView = 45

        let distance = maxDim * 1.8
        cameraNode.simdPosition = simd_float3(
            center.x + distance * 0.5,
            center.y + distance * 0.3,
            center.z + distance
        )
        cameraNode.simdLook(at: center)

        scene.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode
    }

    private func setupLighting(for scene: SCNScene) {
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 200
        ambientLight.light?.color = NSColor.white
        scene.rootNode.addChildNode(ambientLight)
    }
}

// MARK: - SCNView with scroll-to-zoom

class ZoomableSCNView: SCNView {

    override func scrollWheel(with event: NSEvent) {
        guard let cameraNode = self.pointOfView else {
            super.scrollWheel(with: event)
            return
        }

        let zoomSpeed: Float = 0.1
        let delta = Float(event.scrollingDeltaY) * zoomSpeed
        let forward = cameraNode.simdWorldFront
        cameraNode.simdPosition += forward * delta

        // Don't pass to super — we handle zoom ourselves
    }
}
