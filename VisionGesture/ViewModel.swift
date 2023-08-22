import RealityKit
import Observation

@Observable
class ViewModel {
	var logText: String = ""

    private var contentEntity = Entity()

    func setupContentEntity() -> Entity {
        return contentEntity
    }

	func clearText() {
		for child in contentEntity.children {
			contentEntity.removeChild(child)
		}
	}
	
    func addText(text: String) -> Entity {

		logText = text+"\r"+logText
		clearText()

        let textMeshResource: MeshResource = .generateText(logText,
                                                           extrusionDepth: 0.00,
                                                           font: .systemFont(ofSize: 0.05),
                                                           containerFrame: .zero,
														   alignment: .natural,
                                                           lineBreakMode: .byWordWrapping)

		let material = UnlitMaterial(color: .green)

        let textEntity = ModelEntity(mesh: textMeshResource, materials: [material])
		let offsetX: Float = 0.2
//		let offsetX: Float = -(textMeshResource.bounds.extents.x / 2)
		let offsetY = textMeshResource.bounds.extents.y - 1.4
		textEntity.position = SIMD3(x: offsetX, y: 1.5-offsetY, z: -2)
//		textEntity.position = SIMD3(x: -(textMeshResource.bounds.extents.x / 2), y: 1.5, z: -2)

        contentEntity.addChild(textEntity)

        return textEntity
    }
}
