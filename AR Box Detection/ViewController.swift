import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    private var boundingBoxNodes: [SCNNode] = []  // Lista para armazenar os pontos (nós)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar a cena AR
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration)
        
        // Adicionar gesto de toque
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    // Adiciona pontos na cena ao tocar na tela
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        
        // Realiza o hitTest para capturar a posição 3D
        let results = sceneView.hitTest(touchLocation, types: [.featurePoint, .estimatedHorizontalPlane])
        if let result = results.first {
            let position = SCNVector3(result.worldTransform.columns.3.x,
                                      result.worldTransform.columns.3.y,
                                      result.worldTransform.columns.3.z)
            
            // Adiciona um marcador visual e armazena o ponto
            addMarker(at: position)
            boundingBoxNodes.append(createNode(at: position))
            
            // Quando 8 pontos forem adicionados, desenha a bounding box
            if boundingBoxNodes.count == 8 {
                drawBoundingBox()
                calculateVolume()
            }
        }
    }
    
    // Adiciona um marcador visual na posição
    func addMarker(at position: SCNVector3) {
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        let markerNode = SCNNode(geometry: sphere)
        markerNode.position = position
        sceneView.scene.rootNode.addChildNode(markerNode)
    }
    
    // Cria um nó invisível em uma posição específica
    func createNode(at position: SCNVector3) -> SCNNode {
        let node = SCNNode()
        node.position = position
        return node
    }
    
    // Desenha a bounding box com cilindros conectando os pontos
    func drawBoundingBox() {
        let edges = [
            (0, 1), (1, 2), (2, 3), (3, 0), // Base
            (4, 5), (5, 6), (6, 7), (7, 4), // Topo
            (0, 4), (1, 5), (2, 6), (3, 7)  // Laterais
        ]
        
        for edge in edges {
            let start = boundingBoxNodes[edge.0].position
            let end = boundingBoxNodes[edge.1].position
            let line = createLine(from: start, to: end)
            sceneView.scene.rootNode.addChildNode(line)
        }
    }
    
    // Cria uma linha (cilindro) entre dois pontos
    func createLine(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let w = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(start), SCNVector3ToGLKVector3(end)))
        let cylinder = SCNCylinder(radius: 0.0015, height: w)
        cylinder.firstMaterial?.diffuse.contents = UIColor.yellow
        
        let lineNode = SCNNode(geometry: cylinder)
        lineNode.position = SCNVector3((start.x + end.x) / 2,
                                       (start.y + end.y) / 2,
                                       (start.z + end.z) / 2)
        
        let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let axis = SCNVector3(0, 1, 0)
        let quaternion = SCNQuaternion.rotation(from: axis, to: vector)
        lineNode.rotation = quaternion
        
        return lineNode
    }
    
    // Calcula o volume com base nos pontos da bounding box
    func calculateVolume() {
        let width = abs(boundingBoxNodes[1].position.x - boundingBoxNodes[0].position.x)
        let depth = abs(boundingBoxNodes[3].position.z - boundingBoxNodes[0].position.z)
        let height = abs(boundingBoxNodes[4].position.y - boundingBoxNodes[0].position.y)
        
        let volume = width * depth * height
        
        showAlert(width: width, depth: depth, height: height, volume: volume)
    }
    
    // Mostra um alerta com as dimensões e o volume
    func showAlert(width: Float, depth: Float, height: Float, volume: Float) {
        let message = """
        Width: \(String(format: "%.2f", width)) m
        Depth: \(String(format: "%.2f", depth)) m
        Height: \(String(format: "%.2f", height)) m
        Volume: \(String(format: "%.2f", volume)) m³
        """
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Calculated Volume", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

extension SCNQuaternion {
    static func rotation(from start: SCNVector3, to end: SCNVector3) -> SCNQuaternion {
        let cross = SCNVector3(start.y * end.z - start.z * end.y, start.z * end.x - start.x * end.z, start.x * end.y - start.y * end.x)
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
