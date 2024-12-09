import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getDatabase } from "firebase/database";

const firebaseConfig = {
  apiKey: "AIzaSyBHddnE2oaZzAiS9WXWYw7X5ZEf0PZ8B7M",
  authDomain: "bracefaucet.firebaseapp.com",
  databaseURL: "https://bracefaucet-default-rtdb.firebaseio.com",
  projectId: "bracefaucet",
  storageBucket: "bracefaucet.appspot.com",
  messagingSenderId: "27435789987",
  appId: "1:27435789987:ios:10b8e594f9cb807900d916",
  measurementId: undefined,
};

// Inicializa o Firebase
const app = initializeApp(firebaseConfig);

// Exporta os serviços necessários
export const auth = getAuth(app);
export const database = getDatabase(app);

export default app;
