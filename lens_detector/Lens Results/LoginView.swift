import SwiftUI
import FirebaseAuth
import Firebase

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var isRegistering = false
    @State private var isResettingPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToMainPage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(isRegistering ? "Create Account" : (isResettingPassword ? "Reset Password" : "Login"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue.opacity(0.7))

                if isRegistering {
                    TextField("Name", text: $name)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                if !isResettingPassword {
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)

                    if isRegistering {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                Button(action: handleAction) {
                    Text(isRegistering ? "Sign Up" : (isResettingPassword ? "Reset Password" : "Login"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                if !isRegistering && !isResettingPassword {
                    Button(action: {
                        isRegistering = true
                        isResettingPassword = false
                        clearInputs()
                    }) {
                        Text("Create a new account")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        isResettingPassword = true
                        isRegistering = false
                        clearInputs()
                    }) {
                        Text("Forgot password?")
                            .foregroundColor(.blue)
                    }
                } else {
                    Button(action: {
                        isRegistering = false
                        isResettingPassword = false
                        clearInputs()
                    }) {
                        Text("Back to Login")
                            .foregroundColor(.blue)
                    }
                }

                // Nova API de navegação
                NavigationLink(destination: MainPageView()
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true), isActive: $navigateToMainPage) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
            }
            .onAppear {
                checkIfUserIsLoggedIn()
            }
        }
    }

    func handleAction() {
        if isRegistering {
            registerUser()
        } else if isResettingPassword {
            resetPassword()
        } else {
            loginUser()
        }
    }

    func clearInputs() {
        email = ""
        password = ""
        name = ""
        confirmPassword = ""
    }

    func registerUser() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, password == confirmPassword else {
            alertMessage = "Please fill in all fields correctly."
            showAlert = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "Error creating account: \(error.localizedDescription)"
                showAlert = true
                return
            }

            guard let user = result?.user else { return }
            let ref = Database.database().reference().child("users").child(user.uid)
            ref.setValue(["name": name, "email": email]) { error, _ in
                if let error = error {
                    alertMessage = "Error saving data: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    alertMessage = "User successfully created!"
                    showAlert = true
                    isRegistering = false
                    DispatchQueue.main.async {
                        navigateToMainPage = true
                    }
                }
            }
        }
    }

    func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "Login error: \(error.localizedDescription)"
                showAlert = true
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alertMessage = "Login successful!"
                showAlert = true
                navigateToMainPage = true
            }
        }
    }

    func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email."
            showAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                alertMessage = "Error sending reset email: \(error.localizedDescription)"
                showAlert = true
                return
            }

            alertMessage = "Password reset email sent successfully!"
            showAlert = true
            isResettingPassword = false
        }
    }

    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser != nil {
            DispatchQueue.main.async {
                navigateToMainPage = true
            }
        }
    }
}
