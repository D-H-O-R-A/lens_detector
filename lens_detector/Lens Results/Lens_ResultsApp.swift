import SwiftUI
import Firebase

struct SplashScreenView: View {
    @State private var navigateToLogin = false
    init() {
        FirebaseApp.configure() // Inicializa o Firebase
    }
    var body: some View {
        NavigationView {
            ZStack {
                // Fundo azul bebê
                Color.blue.opacity(0.3)
                    .ignoresSafeArea()

                if navigateToLogin {
                    // Navegação para LoginView
                    NavigationLink(destination: LoginView()
                        .navigationBarBackButtonHidden(true) // Remove botão de voltar
                        .navigationBarHidden(true), // Oculta a barra de navegação na LoginView
                                   isActive: $navigateToLogin) {
                        EmptyView()
                    }
                    .hidden()
                } else {
                    // Imagem centralizada e responsiva
                    Image("logo") // Substitua pelo nome da sua imagem no Assets
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                }
            }
            .onAppear {
                // Timer para redirecionar após 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    navigateToLogin = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Para evitar warnings em iPads
        .navigationBarHidden(true) // Oculta a barra de navegação na SplashScreen
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
