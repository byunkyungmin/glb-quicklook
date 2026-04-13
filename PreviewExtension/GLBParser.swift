import Foundation
import SceneKit

// MARK: - Errors

enum GLBError: LocalizedError {
    case invalidFile(String)
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFile(let msg): return "Invalid GLB: \(msg)"
        case .parsingFailed(let msg): return "Parse error: \(msg)"
        }
    }
}

// MARK: - glTF JSON Types

struct GLTFDocument: Codable {
    var scene: Int?
    var scenes: [GLTFScene]?
    var nodes: [GLTFNode]?
    var meshes: [GLTFMesh]?
    var accessors: [GLTFAccessor]?
    var bufferViews: [GLTFBufferView]?
    var buffers: [GLTFBuffer]?
    var materials: [GLTFMaterial]?
}

struct GLTFScene: Codable {
    var nodes: [Int]?
    var name: String?
}

struct GLTFNode: Codable {
    var children: [Int]?
    var mesh: Int?
    var name: String?
    var translation: [Float]?
    var rotation: [Float]?
    var scale: [Float]?
    var matrix: [Float]?
}

struct GLTFMesh: Codable {
    var primitives: [GLTFPrimitive]
    var name: String?
}

struct GLTFPrimitive: Codable {
    var attributes: [String: Int]
    var indices: Int?
    var material: Int?
    var mode: Int?
}

struct GLTFAccessor: Codable {
    var bufferView: Int?
    var byteOffset: Int?
    var componentType: Int
    var count: Int
    var type: String
    var max: [Double]?
    var min: [Double]?
}

struct GLTFBufferView: Codable {
    var buffer: Int
    var byteOffset: Int?
    var byteLength: Int
    var byteStride: Int?
    var target: Int?
}

struct GLTFBuffer: Codable {
    var byteLength: Int
    var uri: String?
}

struct GLTFMaterial: Codable {
    var name: String?
    var pbrMetallicRoughness: GLTFPBR?
    var doubleSided: Bool?
    var emissiveFactor: [Double]?
    var alphaMode: String?
    var alphaCutoff: Double?
}

struct GLTFPBR: Codable {
    var baseColorFactor: [Double]?
    var metallicFactor: Double?
    var roughnessFactor: Double?
}

// MARK: - Parser

class GLBParser {

    func parse(url: URL) throws -> SCNScene {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    func parse(data: Data) throws -> SCNScene {
        guard data.count >= 12 else {
            throw GLBError.invalidFile("File too small")
        }

        let magic = data.readUInt32(at: 0)
        guard magic == 0x46546C67 else {
            throw GLBError.invalidFile("Not a GLB file")
        }

        let version = data.readUInt32(at: 4)
        guard version == 2 else {
            throw GLBError.invalidFile("Unsupported version \(version)")
        }

        let totalLength = Int(data.readUInt32(at: 8))
        guard totalLength <= data.count else {
            throw GLBError.invalidFile("File truncated")
        }

        // Parse chunks
        var jsonData: Data?
        var binData: Data?
        var offset = 12

        while offset + 8 <= totalLength {
            let chunkLength = Int(data.readUInt32(at: offset))
            let chunkType = data.readUInt32(at: offset + 4)
            let chunkStart = offset + 8

            guard chunkStart + chunkLength <= totalLength else { break }

            switch chunkType {
            case 0x4E4F534A: // JSON
                jsonData = data.subdata(in: chunkStart..<(chunkStart + chunkLength))
            case 0x004E4942: // BIN
                binData = data.subdata(in: chunkStart..<(chunkStart + chunkLength))
            default:
                break
            }

            offset = chunkStart + chunkLength
        }

        guard let json = jsonData else {
            throw GLBError.invalidFile("Missing JSON chunk")
        }

        let gltf: GLTFDocument
        do {
            gltf = try JSONDecoder().decode(GLTFDocument.self, from: json)
        } catch {
            throw GLBError.parsingFailed(error.localizedDescription)
        }

        return buildScene(gltf: gltf, bin: binData ?? Data())
    }

    // MARK: - Scene Building

    private func buildScene(gltf: GLTFDocument, bin: Data) -> SCNScene {
        let scene = SCNScene()

        let sceneIndex = gltf.scene ?? 0
        guard let scenes = gltf.scenes, sceneIndex < scenes.count,
              let rootNodes = scenes[sceneIndex].nodes else {
            return scene
        }

        for nodeIndex in rootNodes {
            if let node = buildNode(index: nodeIndex, gltf: gltf, bin: bin) {
                scene.rootNode.addChildNode(node)
            }
        }

        return scene
    }

    private func buildNode(index: Int, gltf: GLTFDocument, bin: Data) -> SCNNode? {
        guard let nodes = gltf.nodes, index < nodes.count else { return nil }
        let gltfNode = nodes[index]
        let node = SCNNode()
        node.name = gltfNode.name

        applyTransform(to: node, from: gltfNode)

        // Mesh
        if let meshIndex = gltfNode.mesh,
           let meshes = gltf.meshes, meshIndex < meshes.count {
            let mesh = meshes[meshIndex]
            if mesh.primitives.count == 1 {
                node.geometry = buildPrimitive(mesh.primitives[0], gltf: gltf, bin: bin)
            } else {
                for prim in mesh.primitives {
                    let primNode = SCNNode()
                    primNode.geometry = buildPrimitive(prim, gltf: gltf, bin: bin)
                    node.addChildNode(primNode)
                }
            }
        }

        // Children
        if let children = gltfNode.children {
            for childIndex in children {
                if let childNode = buildNode(index: childIndex, gltf: gltf, bin: bin) {
                    node.addChildNode(childNode)
                }
            }
        }

        return node
    }

    private func applyTransform(to node: SCNNode, from gltfNode: GLTFNode) {
        if let m = gltfNode.matrix, m.count == 16 {
            // glTF uses column-major matrices
            node.simdTransform = simd_float4x4(columns: (
                simd_float4(m[0], m[1], m[2], m[3]),
                simd_float4(m[4], m[5], m[6], m[7]),
                simd_float4(m[8], m[9], m[10], m[11]),
                simd_float4(m[12], m[13], m[14], m[15])
            ))
        } else {
            if let t = gltfNode.translation, t.count == 3 {
                node.simdPosition = simd_float3(t[0], t[1], t[2])
            }
            if let r = gltfNode.rotation, r.count == 4 {
                node.simdOrientation = simd_quatf(ix: r[0], iy: r[1], iz: r[2], r: r[3])
            }
            if let s = gltfNode.scale, s.count == 3 {
                node.simdScale = simd_float3(s[0], s[1], s[2])
            }
        }
    }

    // MARK: - Geometry

    private func buildPrimitive(_ prim: GLTFPrimitive, gltf: GLTFDocument, bin: Data) -> SCNGeometry? {
        var sources: [SCNGeometrySource] = []

        // Position (required)
        guard let posIndex = prim.attributes["POSITION"],
              let posSource = buildSource(accessorIndex: posIndex, semantic: .vertex, gltf: gltf, bin: bin) else {
            return nil
        }
        sources.append(posSource)

        // Normal
        if let idx = prim.attributes["NORMAL"],
           let src = buildSource(accessorIndex: idx, semantic: .normal, gltf: gltf, bin: bin) {
            sources.append(src)
        }

        // Texture coordinates
        if let idx = prim.attributes["TEXCOORD_0"],
           let src = buildSource(accessorIndex: idx, semantic: .texcoord, gltf: gltf, bin: bin) {
            sources.append(src)
        }

        // Vertex colors
        if let idx = prim.attributes["COLOR_0"],
           let src = buildSource(accessorIndex: idx, semantic: .color, gltf: gltf, bin: bin) {
            sources.append(src)
        }

        // Element
        let element: SCNGeometryElement
        if let indicesIndex = prim.indices {
            guard let el = buildElement(accessorIndex: indicesIndex, gltf: gltf, bin: bin) else { return nil }
            element = el
        } else {
            guard let accessors = gltf.accessors,
                  let posIdx = prim.attributes["POSITION"],
                  posIdx < accessors.count else { return nil }
            let vertexCount = accessors[posIdx].count
            element = SCNGeometryElement(
                data: nil,
                primitiveType: .triangles,
                primitiveCount: vertexCount / 3,
                bytesPerIndex: 0
            )
        }

        let geometry = SCNGeometry(sources: sources, elements: [element])

        // Material
        if let materialIndex = prim.material {
            geometry.materials = [buildMaterial(index: materialIndex, gltf: gltf)]
        } else {
            let mat = SCNMaterial()
            mat.diffuse.contents = NSColor(white: 0.8, alpha: 1.0)
            mat.lightingModel = .physicallyBased
            geometry.materials = [mat]
        }

        return geometry
    }

    private func buildSource(
        accessorIndex: Int,
        semantic: SCNGeometrySource.Semantic,
        gltf: GLTFDocument,
        bin: Data
    ) -> SCNGeometrySource? {
        guard let accessors = gltf.accessors, accessorIndex < accessors.count,
              let bufferViews = gltf.bufferViews else { return nil }

        let accessor = accessors[accessorIndex]
        guard let bvIndex = accessor.bufferView, bvIndex < bufferViews.count else { return nil }
        let bv = bufferViews[bvIndex]

        let components = componentCount(for: accessor.type)
        let bytesPC = bytesPerComponent(for: accessor.componentType)
        let stride = bv.byteStride ?? (components * bytesPC)
        let offset = (bv.byteOffset ?? 0) + (accessor.byteOffset ?? 0)
        let dataLength = (accessor.count - 1) * stride + components * bytesPC

        guard offset >= 0, offset + dataLength <= bin.count else { return nil }

        let data = bin.subdata(in: offset..<(offset + dataLength))

        return SCNGeometrySource(
            data: data,
            semantic: semantic,
            vectorCount: accessor.count,
            usesFloatComponents: accessor.componentType == 5126,
            componentsPerVector: components,
            bytesPerComponent: bytesPC,
            dataOffset: 0,
            dataStride: stride
        )
    }

    private func buildElement(
        accessorIndex: Int,
        gltf: GLTFDocument,
        bin: Data
    ) -> SCNGeometryElement? {
        guard let accessors = gltf.accessors, accessorIndex < accessors.count,
              let bufferViews = gltf.bufferViews else { return nil }

        let accessor = accessors[accessorIndex]
        guard let bvIndex = accessor.bufferView, bvIndex < bufferViews.count else { return nil }
        let bv = bufferViews[bvIndex]

        let bytesPI = bytesPerComponent(for: accessor.componentType)
        let offset = (bv.byteOffset ?? 0) + (accessor.byteOffset ?? 0)
        let dataLength = accessor.count * bytesPI

        guard offset >= 0, offset + dataLength <= bin.count else { return nil }

        let data = bin.subdata(in: offset..<(offset + dataLength))

        return SCNGeometryElement(
            data: data,
            primitiveType: .triangles,
            primitiveCount: accessor.count / 3,
            bytesPerIndex: bytesPI
        )
    }

    // MARK: - Material

    private func buildMaterial(index: Int, gltf: GLTFDocument) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased

        guard let materials = gltf.materials, index < materials.count else {
            material.diffuse.contents = NSColor(white: 0.8, alpha: 1.0)
            return material
        }

        let gm = materials[index]
        material.name = gm.name

        if let pbr = gm.pbrMetallicRoughness {
            if let c = pbr.baseColorFactor, c.count >= 4 {
                material.diffuse.contents = NSColor(
                    red: CGFloat(c[0]), green: CGFloat(c[1]),
                    blue: CGFloat(c[2]), alpha: CGFloat(c[3])
                )
            }
            material.metalness.contents = NSNumber(value: pbr.metallicFactor ?? 1.0)
            material.roughness.contents = NSNumber(value: pbr.roughnessFactor ?? 1.0)
        }

        if let e = gm.emissiveFactor, e.count >= 3 {
            material.emission.contents = NSColor(
                red: CGFloat(e[0]), green: CGFloat(e[1]),
                blue: CGFloat(e[2]), alpha: 1.0
            )
        }

        if gm.doubleSided == true {
            material.isDoubleSided = true
        }

        if gm.alphaMode == "BLEND" {
            material.blendMode = .alpha
            material.transparencyMode = .dualLayer
        }

        return material
    }

    // MARK: - Helpers

    private func componentCount(for type: String) -> Int {
        switch type {
        case "SCALAR": return 1
        case "VEC2":   return 2
        case "VEC3":   return 3
        case "VEC4":   return 4
        case "MAT2":   return 4
        case "MAT3":   return 9
        case "MAT4":   return 16
        default:       return 1
        }
    }

    private func bytesPerComponent(for componentType: Int) -> Int {
        switch componentType {
        case 5120, 5121: return 1  // BYTE, UNSIGNED_BYTE
        case 5122, 5123: return 2  // SHORT, UNSIGNED_SHORT
        case 5125, 5126: return 4  // UNSIGNED_INT, FLOAT
        default:         return 4
        }
    }
}

// MARK: - Data Extension

extension Data {
    func readUInt32(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        return withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
    }
}
