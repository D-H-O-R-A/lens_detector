import SwiftUI
import WebKit

@main
struct LensImageApp: App { // Ponto de entrada principal do aplicativo
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}

struct SplashScreenView: View {
    var body: some View {
        WebView(url: URL(string: "https://lensimage.site")!) // Substitua pela URL do website
            .edgesIgnoringSafeArea(.all) // Permite que o WebView ocupe toda a tela
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let dataStore = WKWebsiteDataStore.nonPersistent()
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = dataStore
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        webConfiguration.defaultWebpagePreferences = webpagePreferences
        
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "cameraAccess")
        webConfiguration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.load(URLRequest(url: url))
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            // Implementar um alerta para substituir alertas padrão
            print("JavaScript Alert: \(message)")
            completionHandler()
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "cameraAccess" {
                print("Camera access requested.")
            } else {
                print("Unexpected script message received: \(message.name)")
            }
        }
        
        // Abrir links externos no navegador padrão
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               navigationAction.navigationType == .linkActivated,
               url.host != "lensimage.site" { // Substitua por seu domínio, se necessário
                UIApplication.shared.open(url) // Abre no navegador padrão
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
