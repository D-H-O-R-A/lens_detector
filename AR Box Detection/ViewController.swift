import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar a cena AR
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        // Configuração do ARKit para detecção de planos
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
    }
    
    // Função chamada quando um plano é detectado
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        addBoundingBox(for: planeAnchor, on: node)
    }
    
    // Adiciona uma bounding box com linhas feitas por cilindros
    func addBoundingBox(for anchor: ARPlaneAnchor, on node: SCNNode) {
        let width = anchor.extent.x
        let depth = anchor.extent.z
        let height: Float = 0.3 // Altura padrão da caixa
        
        // Coordenadas dos vértices
        let vertices: [SCNVector3] = [
            SCNVector3(-width / 2, 0, -depth / 2),
            SCNVector3(width / 2, 0, -depth / 2),
            SCNVector3(width / 2, 0, depth / 2),
            SCNVector3(-width / 2, 0, depth / 2),
            SCNVector3(-width / 2, height, -depth / 2),
            SCNVector3(width / 2, height, -depth / 2),
            SCNVector3(width / 2, height, depth / 2),
            SCNVector3(-width / 2, height, depth / 2)
        ]
        
        // Arestas conectando os vértices
        let edges = [
            (0, 1), (1, 2), (2, 3), (3, 0), // Base
            (4, 5), (5, 6), (6, 7), (7, 4), // Topo
            (0, 4), (1, 5), (2, 6), (3, 7)  // Laterais
        ]
        
        // Desenha as linhas conectando os vértices
        for edge in edges {
            let start = vertices[edge.0]
            let end = vertices[edge.1]
            let line = createLine(from: start, to: end)
            node.addChildNode(line)
        }
        
        // Calcular e exibir o volume
        let volume = width * depth * height
        showVolumeAlert(width: width, depth: depth, height: height, volume: volume)
    }
    
    // Cria uma linha entre dois pontos usando um cilindro fino
    func createLine(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let w = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(start), SCNVector3ToGLKVector3(end)))
        let cylinder = SCNCylinder(radius: 0.002, height: w)
        cylinder.firstMaterial?.diffuse.contents = UIColor.yellow
        
        let lineNode = SCNNode(geometry: cylinder)
        
        // Posiciona a linha no meio entre os dois pontos
        lineNode.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        
        // Calcula a rotação correta usando quaternions
        let vector = SCNVector3Make(end.x - start.x, end.y - start.y, end.z - start.z)
        let axis = SCNVector3Make(0, 1, 0) // Eixo do cilindro padrão
        lineNode.rotation = SCNQuaternion.rotation(from: axis, to: vector)
        
        return lineNode
    }
    
    // Exibe alerta com o volume calculado
    func showVolumeAlert(width: Float, depth: Float, height: Float, volume: Float) {
        let message = """
        Largura: \(String(format: "%.2f", width)) m
        Profundidade: \(String(format: "%.2f", depth)) m
        Altura: \(String(format: "%.2f", height)) m
        Volume: \(String(format: "%.2f", volume)) m³
        """
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Volume Detectado", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// Extensão para quaternions: rotação entre dois vetores
extension SCNQuaternion {
    static func rotation(from start: SCNVector3, to end: SCNVector3) -> SCNQuaternion {
        let cross = SCNVector3Make(
            start.y * end.z - start.z * end.y,
            start.z * end.x - start.x * end.z,
            start.x * end.y - start.y * end.x
        )
        let dot = start.x * end.x + start.y * end.y + start.z * end.z
        let angle = acos(dot / (start.length() * end.length()))
        
        return SCNQuaternion(cross.x, cross.y, cross.z, angle)
    }
}

extension SCNVector3 {
    func length() -> Float {
        return sqrt(x * x + y * y + z * z)
    }
}
