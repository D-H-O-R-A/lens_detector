import React, { useEffect, useState } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import Login from "./Login"; // Componente de Login
import MainPage from "./Main"; // Componente da Página Principal
import { logo } from "./img/image";

const App = () => {
  const [navigateToLogin, setNavigateToLogin] = useState(false);

  useEffect(() => {
    // Define um timer para redirecionar para o login após 3 segundos
    const timer = setTimeout(() => setNavigateToLogin(true), 3000);
    return () => clearTimeout(timer); // Limpa o timer ao desmontar
  }, []);

  return (
    <Router>
      <Routes>
        {/* Tela de Splash */}
        <Route
          path="/"
          element={
            navigateToLogin ? (
              <Navigate to="/login" replace />
            ) : (
              <div style={styles.splashContainer}>
                <img src={logo} alt="Logo" style={styles.logo} />
              </div>
            )
          }
        />
        {/* Tela de Login */}
        <Route path="/login" element={<Login />} />
        {/* Página Principal */}
        <Route path="/main" element={<MainPage />} />
        {/* Redirecionamento para a Splash por padrão */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
};

const styles = {
  splashContainer: {
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    height: "100vh",
    backgroundColor: "#d8eaff",
  },
  logo: {
    maxWidth: "300px",
  },
};

export default App;
