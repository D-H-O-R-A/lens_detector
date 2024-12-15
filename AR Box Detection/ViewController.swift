//
//  ViewController.swift
//  AR Box Detection
//
//  Created by user268572 on 12/15/24.
//
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
        let height: Float = 0.5 // Altura padrão
        
        // Posições dos vértices
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
        
        // Linhas entre os vértices (arestas da caixa)
        let edges = [
            (0, 1), (1, 2), (2, 3), (3, 0), // Base
            (4, 5), (5, 6), (6, 7), (7, 4), // Topo
            (0, 4), (1, 5), (2, 6), (3, 7)  // Laterais
        ]
        
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
        lineNode.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        
        lineNode.eulerAngles = SCNVector3.lineEulerAngles(from: start, to: end)
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

// Extensão para calcular ângulos de rotação
extension SCNVector3 {
    static func lineEulerAngles(from start: SCNVector3, to end: SCNVector3) -> SCNVector3 {
        let delta = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let height = sqrt(delta.x * delta.x + delta.z * delta.z)
        let pitch = -atan2(delta.y, height)
        let yaw = atan2(delta.x, delta.z)
        return SCNVector3(pitch, yaw, 0)
    }
}
