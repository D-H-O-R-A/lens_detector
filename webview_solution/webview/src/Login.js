import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { auth, database } from "./firebaseConfig";
import { onAuthStateChanged, createUserWithEmailAndPassword, signInWithEmailAndPassword, sendPasswordResetEmail } from "firebase/auth";
import { ref, set } from "firebase/database";
import Swal from "sweetalert2";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isRegistering, setIsRegistering] = useState(false);
  const [isResettingPassword, setIsResettingPassword] = useState(false);
  const navigate = useNavigate();

  // Verifica se o usuário está logado ao carregar o componente
  useEffect(() => {
    onAuthStateChanged(auth, (user) => {
      if (user) {
        navigate("/main");
      } else {
        console.log("Nenhum usuário logado.");
      }
    });
  }, [navigate]);

  const handleAction = async () => {
    try {
      if (isRegistering) {
        // Cadastro de novo usuário
        if (password !== confirmPassword) {
          Toast.fire({
            icon: "error",
            title: "Passwords do not match!",
          });
          return;
        }

        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;

        // Armazena informações adicionais no Realtime Database
        await set(ref(database, `users/${user.uid}`), { name, email });

        Toast.fire({
          icon: "success",
          title: "Account created successfully!",
        });

        navigate("/main");
      } else if (isResettingPassword) {
        // Redefinição de senha
        await sendPasswordResetEmail(auth, email);
        Toast.fire({
          icon: "success",
          title: "Password reset email sent!",
        });
        setIsResettingPassword(false);
      } else {
        // Login de usuário
        await signInWithEmailAndPassword(auth, email, password);
        Toast.fire({
          icon: "success",
          title: "Logged in successfully!",
        });

        navigate("/main");
      }
    } catch (error) {
      Toast.fire({
        icon: "error",
        title: error.message,
      });
    }
  };

  const clearInputs = () => {
    setEmail("");
    setPassword("");
    setName("");
    setConfirmPassword("");
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>
          {isRegistering
            ? "Create Account"
            : isResettingPassword
            ? "Reset Password"
            : "Login"}
        </h1>

        {isRegistering && (
          <input
            type="text"
            placeholder="Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            style={styles.input}
          />
        )}

        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          style={styles.input}
        />

        {!isResettingPassword && (
          <>
            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={styles.input}
            />
            {isRegistering && (
              <input
                type="password"
                placeholder="Confirm Password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                style={styles.input}
              />
            )}
          </>
        )}

        <button onClick={handleAction} style={styles.actionButton}>
          {isRegistering
            ? "Sign Up"
            : isResettingPassword
            ? "Reset Password"
            : "Login"}
        </button>

        {!isRegistering && !isResettingPassword ? (
          <>
            <button
              onClick={() => {
                setIsRegistering(true);
                setIsResettingPassword(false);
                clearInputs();
              }}
              style={styles.link}
            >
              Create a new account
            </button>
            <button
              onClick={() => {
                setIsResettingPassword(true);
                setIsRegistering(false);
                clearInputs();
              }}
              style={styles.link}
            >
              Forgot password?
            </button>
          </>
        ) : (
          <button
            onClick={() => {
              setIsRegistering(false);
              setIsResettingPassword(false);
              clearInputs();
            }}
            style={styles.link}
          >
            Back to Login
          </button>
        )}
      </div>
    </div>
  );
};

const Toast = Swal.mixin({
  toast: true,
  position: "top-end",
  showConfirmButton: false,
  timer: 3000,
});

const styles = {
  container: {
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    minHeight: "100vh",
    backgroundColor: "#ffffff",
    padding: "20px",
  },
  card: {
    backgroundColor: "#ffffff",
    borderRadius: "10px",
    padding: "20px",
    width: "100%",
    maxWidth: "400px",
    textAlign: "center",
  },
  title: {
    fontSize: "24px",
    fontWeight: "bold",
    color: "#007bff",
    marginBottom: "20px",
  },
  input: {
    width: "100%",
    padding: "10px",
    margin: "10px 0",
    borderRadius: "5px",
    backgroundColor: "rgba(0, 123, 255, 0.1)",
    border: "none",
    outline: "none",
    fontSize: "16px",
  },
  actionButton: {
    width: "100%",
    backgroundColor: "#007bff",
    color: "#ffffff",
    border: "none",
    padding: "10px",
    borderRadius: "5px",
    fontSize: "16px",
    cursor: "pointer",
  },
  link: {
    backgroundColor: "transparent",
    border: "none",
    color: "#007bff",
    textDecoration: "none",
    marginTop: "10px",
    cursor: "pointer",
  },
};

export default Login;
