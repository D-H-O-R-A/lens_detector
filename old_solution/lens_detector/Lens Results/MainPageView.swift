import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import PhotosUI
import WebKit

struct MainPageView: View {
    @State private var isLoggedIn = true
    @State private var selectedImage: UIImage?
    @State private var imageURL: String = ""
    @State private var uploadProgress: Double = 0.0
    @State private var showPhotoPicker = false
    @State private var isUploading = false
    @State private var showLoadingScreen = false
    @State private var loadingText = "Performing search... please wait!"
    @State private var showResults = false
    @State private var htmlContent = ""
    @State private var rotationAngle: Double = 0
    @State private var favorites: [Favorite] = []

    struct Favorite: Identifiable {
        let id: String
        let html: String
    }

    var body: some View {
        VStack {
            if showLoadingScreen {
                loadingScreen
            } else if showResults {
                resultsScreen
            } else {
                mainScreen
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            checkAuthentication()
            loadFavoritesFromFirebase()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(image: $selectedImage) {
                uploadImage()
            }
        }
    }

    private var mainScreen: some View {
        VStack(spacing: 16) {
            header
            searchWidget
            favoritesSection
            if isUploading {
                uploadProgressView
            }
            Spacer()
        }
    }

    private var header: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 179/255, green: 229/255, blue: 252/255),
                    Color.white
                ]),
                startPoint: .center,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Lens Search")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: logOut) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 179/255, green: 229/255, blue: 252/255))
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .rotationEffect(.degrees(90))
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .frame(height: 150)
    }

    private var searchWidget: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            HStack(spacing: 8) {
                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 179/255, green: 229/255, blue: 252/255))
                        .clipShape(Circle())
                }

                Button(action: {
                    showPhotoPicker.toggle()
                }) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundColor(Color(red: 179/255, green: 229/255, blue: 252/255))
                        Text("Pick Image")
                            .foregroundColor(Color(red: 179/255, green: 229/255, blue: 252/255))
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 179/255, green: 229/255, blue: 252/255), lineWidth: 2)
                    )
                }
            }
            .padding(8)
        }
        .frame(width: 350, height: 60)
        .padding(.horizontal)
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Favorites")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.leading, 16)

            if favorites.isEmpty {
                Text("No favorites saved.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.leading, 16)
            } else {
                List(favorites) { favorite in
                    Button(action: {
                        loadFavorite(favorite.html)
                    }) {
                        Text(favorite.html)
                            .lineLimit(1)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(.top, 8)
    }

    private var uploadProgressView: some View {
        VStack {
            ProgressView(value: uploadProgress, total: 1.0)
                .padding(.horizontal)
            Text("Uploading: \(Int(uploadProgress * 100))%")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }

    private var loadingScreen: some View {
        VStack {
            ZStack {
                Color(red: 179/255, green: 229/255, blue: 252/255)
                    .ignoresSafeArea()

                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 230, height: 230)
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 210, height: 210)
                            .rotationEffect(Angle.degrees(rotationAngle))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                                    rotationAngle = 360
                                }
                            }
                    }
                    Text(loadingText)
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 16)
                }
            }
        }
    }

    private var resultsScreen: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Results")
                    .font(.title)
                    .bold()
                Spacer()
                Button("Favorite") {
                    saveFavoriteToFirebase(htmlContent)
                }
                Button("Back") {
                    showResults = false
                }
            }
            .padding(.horizontal)

            StyledWebView(htmlContent: formattedHTML)
                .frame(maxHeight: .infinity)

            Spacer()
        }
    }
    
    func checkAuthentication() {
        if Auth.auth().currentUser == nil {
            isLoggedIn = false
        }
    }
    
    func performSearch() {
        guard !imageURL.isEmpty else {
            print("Please add an image first.")
            return
        }
        showLoadingScreen = true
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showLoadingScreen = false
            self.showResults = true
        }
    }

    func logOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            print("User logged out successfully")
        } catch let error {
            print("Failed to log out: \(error.localizedDescription)")
        }
    }

    func uploadImage() {
        guard let selectedImage = selectedImage else { return }
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else { return }

        let storage = Storage.storage()
        let storageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
        isUploading = true

        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            isUploading = false
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to retrieve download URL: \(error.localizedDescription)")
                    return
                }
                imageURL = url?.absoluteString ?? ""
                print("Image uploaded successfully. URL: \(imageURL)")
            }
        }

        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
        }
    }

    func loadFavoritesFromFirebase() {
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated.")
            return
        }

        let databaseRef = Database.database().reference()
        let favoritesRef = databaseRef.child("user/\(user.uid)/favoritos")

        favoritesRef.observe(.value) { snapshot in
            var loadedFavorites: [Favorite] = []

            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let value = childSnapshot.value as? [String: String],
                   let html = value["html"] {
                    let favorite = Favorite(id: childSnapshot.key, html: html)
                    loadedFavorites.append(favorite)
                }
            }

            self.favorites = loadedFavorites
        }
    }

    func saveFavoriteToFirebase(_ content: String) {
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated.")
            return
        }

        let databaseRef = Database.database().reference()
        let favoritesRef = databaseRef.child("user/\(user.uid)/favoritos")

        let newFavorite = ["html": content]
        favoritesRef.childByAutoId().setValue(newFavorite) { error, _ in
            if let error = error {
                print("Failed to save favorite: \(error.localizedDescription)")
            } else {
                print("Favorite saved successfully!")
                loadFavoritesFromFirebase()
            }
        }
    }

    func loadFavorite(_ html: String) {
        htmlContent = html
        showResults = true
    }

    var formattedHTML: String {
        """
        <html>
        <head>
        <style>
        body {
            font-family: Arial, sans-serif;
            padding: 20px;
            margin: 0;
            background-color: #f9f9f9;
            color: #333;
        }
        a {
            text-decoration: none;
            color: #007bff;
            font-size: 18px;
            margin-bottom: 12px;
            display: block;
            transition: color 0.3s ease, transform 0.3s ease;
        }
        a:hover {
            color: #0056b3;
            transform: translateX(5px);
        }
        </style>
        </head>
        <body>
        \(htmlContent)
        </body>
        </html>
        """
    }
}

struct StyledWebView: UIViewRepresentable {
    var htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: StyledWebView

        init(_ parent: StyledWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url) // Abre o link no navegador externo
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                    self.parent.onComplete()
                }
            }
        }
    }
}
