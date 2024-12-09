import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { auth, database } from "./firebaseConfig";
import { signOut, onAuthStateChanged } from "firebase/auth";
import { ref, onValue, push } from "firebase/database";
import {
  getStorage,
  ref as storageRef,
  uploadBytesResumable,
  getDownloadURL,
} from "firebase/storage";
import Swal from "sweetalert2";
import { logo, coracao } from "./img/image";
import { getLens } from "./getLensAPI";
import "bootstrap/dist/css/bootstrap.min.css";
import "./Main.css";

const Toast = Swal.mixin({
  toast: true,
  position: "top-end",
  showConfirmButton: false,
  timer: 3000,
  timerProgressBar: true,
  didOpen: (toast) => {
    toast.onmouseenter = Swal.stopTimer;
    toast.onmouseleave = Swal.resumeTimer;
  },
});

const MainScreen = () => {
  const [imageURL, setImageURL] = useState("");
  const [textInfo, setTextInfo] = useState("Click to search image");
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [showResults, setShowResults] = useState(false);
  const [showLoadingScreen, setShowLoadingScreen] = useState(true);
  const [htmlContent, setHtmlContent] = useState([]);
  const [favorites, setFavorites] = useState([]);
  const [showFavorites, setShowFavorites] = useState(false); // Novo estado para exibir "Favorites"
  const navigate = useNavigate();
  const storage = getStorage();

  useEffect(() => {
    onAuthStateChanged(auth, (user) => {
      if (!user) {
        navigate("/login");
      } else {
        loadFavoritesFromFirebase(); // Carrega favoritos ao autenticar
      }
    });
  }, [navigate]);

  useEffect(() => {
    if (imageURL && !showFavorites && !showResults) {
      performSearch();
    }
  }, [imageURL, showFavorites, showResults]);

  const logOut = async () => {
    await signOut(auth);
    Toast.fire("Logged Out", "You have been logged out successfully!", "success");
    navigate("/login");
  };

  const loadFavoritesFromFirebase = () => {
    const user = auth.currentUser;
    if (!user) return;

    const dbRef = ref(database, `users/${user.uid}/favorites`);
    onValue(dbRef, (snapshot) => {
      const data = snapshot.val();
      if (data) {
        setFavorites(
          Object.entries(data).map(([id, value]) => ({
            id,
            html: value.html || [],
            image: value.image || "",
          }))
        );
      }
    });
  };

  const saveFavoriteToFirebase = () => {
    const user = auth.currentUser;
    if (!user) {
      Toast.fire("Error", "You need to log in to save favorites!", "error");
      return;
    }

    const dbRef = ref(database, `users/${user.uid}/favorites`);
    push(dbRef, { html: htmlContent, image: imageURL });
    Toast.fire("Success", "Added to favorites!", "success");
  };

  const uploadImage = async () => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/*";
    input.style.display = "none";

    input.onchange = async (event) => {
      const file = event.target.files[0];
      if (!file) {
        Toast.fire("Error", "No file selected!", "error");
        return;
      }

      const fileRef = storageRef(storage, `images/${Date.now()}-${file.name}`);
      const uploadTask = uploadBytesResumable(fileRef, file);

      setIsUploading(true);
      setTextInfo("Uploading...");

      uploadTask.on(
        "state_changed",
        (snapshot) => {
          const progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          setUploadProgress(progress);
          setTextInfo(`Uploading... ${Math.round(progress)}%`);
        },
        (error) => {
          console.error("Upload failed:", error);
          Toast.fire("Error", error.message, "error");
          setIsUploading(false);
          setTextInfo("Upload failed. Please try again.");
        },
        async () => {
          const url = await getDownloadURL(fileRef);
          setImageURL(url);
          setIsUploading(false);
          setTextInfo("Image uploaded successfully!");
          Toast.fire("Success", "Image uploaded successfully!", "success");
        }
      );
    };

    document.body.appendChild(input);
    input.click();
    document.body.removeChild(input);
  };

  const performSearch = async () => {
    if (!imageURL) {
      Toast.fire("Error", "Please upload an image before searching!", "error");
      return;
    }

    setTextInfo("Getting results...");
    setShowLoadingScreen(true);

    try {
      const links = await getLens(encodeURIComponent(imageURL));
      setHtmlContent(links.html);
      setShowResults(true);
    } catch (error) {
      Toast.fire("Error", "Search failed. Please try again later.", "error");
    } finally {
      setShowLoadingScreen(false);
    }
  };

  const resetToDefault = () => {
    setImageURL("");
    setTextInfo("Click to search image");
    setShowResults(false);
    setShowLoadingScreen(true);
    setShowFavorites(false);
  };

  const openFavorites = () => {
    loadFavoritesFromFirebase(); // Garante carregar os favoritos ao clicar no botão
    setShowFavorites(true);
    setShowLoadingScreen(false);
  };

  const closeFavorites = () => {
    setShowFavorites(false);
    setShowLoadingScreen(true);
  };

  const handleFavoriteClick = (favorite) => {
    setImageURL(favorite.image); // Define a imagem do favorito
    setHtmlContent(favorite.html); // Define os links do favorito
    setShowFavorites(false);
    setShowResults(true); // Vai direto para a tela de resultados
  };

  return (
    <div
      className="container d-flex justify-content-center align-items-center vh-100"
      style={{
        background: showResults ? "#ffffff" : showFavorites ? "#ffffff" : "#9ad6f2",
      }}
    >
      {showFavorites ? (
        <div className="container py-4" style={{ backgroundColor: "#ffffff", color: "#333" }}>
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h1 className="fw-bold">Favorites</h1>
            <a
              href="#"
              className="text-decoration-none"
              style={{ color: "#333" }}
              onClick={closeFavorites}
            >
              Back
            </a>
          </div>

          <div
            className="overflow-auto"
            style={{
              maxHeight: "70vh",
              overflowX: "scroll",
            }}
          >
            <ul className="list-unstyled">
              {favorites.length > 0 ? (
                favorites.map((favorite, index) => (
                  <li
                    key={index}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      padding: "10px",
                      borderTop: "1px solid #ddd",
                      borderBottom: "1px solid #ddd",
                    }}
                    onClick={() => handleFavoriteClick(favorite)}
                  >
                    <img
                      src={favorite.image}
                      alt="Favorite"
                      style={{
                        height: "40px",
                        width: "40px",
                        marginRight: "10px",
                      }}
                    />
                    <span
                      className="text-decoration-none"
                      style={{
                        wordBreak: "break-word",
                        flex: 1,
                        color: "#333",
                      }}
                    >
                      {favorite.html[0] || "No URL available"}
                    </span>
                  </li>
                ))
              ) : (
                <p className="text-center mt-3" style={{ color: "#333" }}>
                  No favorites found.
                </p>
              )}
            </ul>
          </div>
        </div>
      ) : showLoadingScreen ? (
        <div className="position-relative text-center ccroder">
          {/* Botão de Logout no canto superior esquerdo */}
          <button
            className="btn position-fixed top-0 start-0 m-3 p-2 btn-danger"
            onClick={logOut}
            style={{
              fontSize: "0.9rem",
              fontWeight: "bold",
              borderRadius: "5px",
            }}
          >
            Logout
          </button>

          {/* Botão de favoritos */}
          <button
            className="btn position-fixed top-0 end-0 m-3 p-0"
            style={{
              backgroundColor: "transparent",
              border: "none",
            }}
            onClick={openFavorites}
          >
            <img
              src={coracao}
              alt="Favorites"
              style={{ height: "30px", width: "30px" }}
            />
          </button>

          <div className="rotating-image" onClick={uploadImage}>
            <img src={logo} alt="Rotating Logo" className="img-fluid rounded-circle" />
          </div>
          <p className="mt-3 text-light fs-5">{textInfo}</p>
        </div>
      ) : showResults ? (
        <div
          className="container py-4"
          style={{
            backgroundColor: "#ffffff",
            color: "#333",
          }}
        >
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h1 className="fw-bold">Results</h1>
            <div>
              <a
                href="#"
                className="text-decoration-none me-3"
                style={{ color: "#333" }}
                onClick={saveFavoriteToFirebase}
              >
                Favorite
              </a>
              <a
                href="#"
                className="text-decoration-none"
                style={{ color: "#333" }}
                onClick={resetToDefault}
              >
                Back
              </a>
            </div>
          </div>

          <div
            className="overflow-auto"
            style={{
              maxHeight: "70vh",
              overflowX: "scroll",
            }}
          >
            <ul className="list-unstyled">
              {htmlContent.map((link, index) => (
                <li
                  key={index}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "10px",
                    borderTop: "1px solid #ddd",
                    borderBottom: "1px solid #ddd",
                  }}
                >
                  <img
                    src={imageURL}
                    alt="Searched"
                    style={{
                      height: "40px",
                      width: "40px",
                      marginRight: "10px",
                    }}
                  />
                  <a
                    href={link}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-decoration-none"
                    style={{
                      wordBreak: "break-word",
                      flex: 1,
                      color: "#333",
                    }}
                  >
                    {link}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>
      ) : null}
    </div>
  );
};

export default MainScreen;
