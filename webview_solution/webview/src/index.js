import React from "react";
import ReactDOM from 'react-dom/client'; // Importação atualizada para React 18
import App from "./App";
import "./index.css"; // Estilos globais, se necessário

const rootElement = document.getElementById('root');

// Crie o root e renderize o App
const root = ReactDOM.createRoot(rootElement);

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
